import ChessTraining
import Foundation
import Observation
import SwiftUI
#if canImport(GameKit)
@preconcurrency import GameKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Somebody on the rank list, among the players, or in the friends list.
struct BoardPlayer: Identifiable, Equatable {
    let id: String
    let alias: String
    let rank: Int?
    let rating: Int?
    let clock: TimeControl?
    let lastSeen: Date
    let isLocal: Bool
    /// Their 32-hex account ID on `OnlineService`.
    var key: String? = nil

    func isActive(at now: Date = Date()) -> Bool {
        now.timeIntervalSince(lastSeen) < OnlineBoards.activeWindow
    }
}

/// Rank lists, player directory, presence, and friends backed by the Brass Pawn
/// online service (`/brasspawn/v1/`), with optional Game Center photo/friend
/// enrichment and best-effort Game Center leaderboard mirroring.
@MainActor
@Observable
final class OnlineBoards {
    nonisolated static let activeWindow: TimeInterval = 7 * 86_400
    static let pageSize = 100

    enum Scope: String, CaseIterable, Identifiable {
        case top, around, friends
        var id: String { rawValue }

        var title: String {
            switch self {
            case .top: L.t("online.scope.top", "Top")
            case .around: L.t("online.scope.around", "Around you")
            case .friends: L.t("online.scope.friends", "Friends")
            }
        }
    }

    static func leaderboardID(_ control: TimeControl) -> String {
        "brasspawn.online.\(control.minutes)"
    }

    private(set) var ranks: [TimeControl: [BoardPlayer]] = [:]
    private(set) var aroundRanks: [TimeControl: [BoardPlayer]] = [:]
    private(set) var friendRanks: [TimeControl: [BoardPlayer]] = [:]
    private(set) var mine: [TimeControl: BoardPlayer] = [:]
    private(set) var friendMine: [TimeControl: BoardPlayer] = [:]
    private(set) var totals: [TimeControl: Int] = [:]
    private(set) var friendTotals: [TimeControl: Int] = [:]

    /// Everybody met on any list or online right now, most recently seen first.
    private(set) var everyone: [BoardPlayer] = []
    /// Recent Game Center opponents where available.
    private(set) var recent: [BoardPlayer] = []
    /// Friends and pending requests on the service.
    private(set) var friends: [BoardPlayer] = []
    private(set) var incoming: [BoardPlayer] = []
    private(set) var outgoing: [BoardPlayer] = []
    /// Game Center friends who are not yet friends on the service.
    private(set) var gameCenterFriends: [BoardPlayer] = []

    enum FriendState { case none, friend, asked, askedBy }

    private var friendsSnapshot: OnlineFriends?
    private var latest: [String: BoardPlayer] = [:]
    private(set) var lookingNow: [TimeControl: Int] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var photos: [String: Image] = [:]

    #if canImport(GameKit)
    /// Known `GKPlayer` objects keyed by `id` (either `gamePlayerID` or 32-hex account key).
    private var players: [String: GKPlayer] = [:]
    func player(_ id: String) -> GKPlayer? { players[id] }
    #endif

    private(set) var presence: [String: PresenceStatus] = [:]
    private var playerIDsByKey: [String: String] = [:]
    private var presenceByKey: [String: PresenceStatus] = [:]

    func entries(for control: TimeControl, scope: Scope) -> [BoardPlayer] {
        switch scope {
        case .top: ranks[control] ?? []
        case .around: aroundRanks[control] ?? ranks[control] ?? []
        case .friends: friendRanks[control] ?? []
        }
    }

    func myEntry(for control: TimeControl, scope: Scope) -> BoardPlayer? {
        switch scope {
        case .top, .around: mine[control]
        case .friends: friendMine[control]
        }
    }

    func total(for control: TimeControl, scope: Scope) -> Int {
        switch scope {
        case .top, .around: totals[control] ?? (ranks[control]?.count ?? 0)
        case .friends: friendTotals[control] ?? (friendRanks[control]?.count ?? 0)
        }
    }

    /// Everybody on screen now, looking for a game first.
    func onlineNow() -> [BoardPlayer] {
        var seen = Set<String>()
        return (everyone + recent + friends)
            .filter { !$0.isLocal && status(of: $0) != nil && seen.insert($0.key ?? $0.id).inserted }
            .sorted { statusOrder(status(of: $0)) < statusOrder(status(of: $1)) }
    }

    private func statusOrder(_ status: PresenceStatus?) -> Int {
        switch status {
        case .looking: 0
        case .online: 1
        case .playing: 2
        case nil: 3
        }
    }

    /// Whether a player can be invited directly (either as a service friend or via Game Center).
    func canInvite(_ player: BoardPlayer) -> Bool {
        if player.key != nil && friendState(of: player) == .friend { return true }
        #if canImport(GameKit)
        if players[player.id] != nil { return true }
        if let key = player.key, players[key] != nil { return true }
        #endif
        return false
    }

    func friendState(of player: BoardPlayer) -> FriendState {
        let same = { (other: BoardPlayer) in
            other.id == player.id || (other.key != nil && other.key == player.key)
        }
        if friends.contains(where: same) { return .friend }
        if outgoing.contains(where: same) { return .asked }
        if incoming.contains(where: same) { return .askedBy }
        return .none
    }

    func status(of player: BoardPlayer) -> PresenceStatus? {
        presence[player.id] ?? player.key.flatMap { presenceByKey[$0] }
    }

    func active(at now: Date = Date()) -> [BoardPlayer] {
        var seen = Set<String>()
        return everyone.filter {
            !$0.isLocal && status(of: $0) == nil && $0.isActive(at: now) && seen.insert($0.key ?? $0.id).inserted
        }
    }

    func inactive(at now: Date = Date()) -> [BoardPlayer] {
        var seen = Set<String>()
        return everyone.filter {
            !$0.isLocal && status(of: $0) == nil && !$0.isActive(at: now) && seen.insert($0.key ?? $0.id).inserted
        }
    }

    // MARK: - Service Refresh

    func refresh(using service: OnlineService) async {
        guard service.isSignedIn, !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        let myAccount = service.account ?? ""
        latest = [:]

        for control in TimeControl.allCases {
            guard let board = await service.leaderboard(minutes: control.minutes, scope: Scope.top.rawValue, limit: Self.pageSize) else {
                continue
            }
            ranks[control] = absorb(board.entries, on: control, myAccount: myAccount)
            totals[control] = board.total
            mine[control] = board.me.map { toBoardPlayer($0, on: control, myAccount: myAccount) }
        }
        rebuildEveryone()

        #if canImport(GameKit)
        if GKLocalPlayer.local.isAuthenticated,
           let played = try? await GKLocalPlayer.local.loadRecentPlayers() {
            recent = played.prefix(12).map(knownGameCenterPlayer)
        }
        #endif

        if let friendsSnapshot {
            take(friendsSnapshot, myAccount: myAccount)
        }
        await refreshPresence(using: service)
    }

    func loadScope(_ scope: Scope, on control: TimeControl, using service: OnlineService) async {
        guard service.isSignedIn else { return }
        let myAccount = service.account ?? ""
        guard let board = await service.leaderboard(minutes: control.minutes, scope: scope.rawValue, limit: Self.pageSize) else {
            return
        }
        let mapped = absorb(board.entries, on: control, myAccount: myAccount)
        switch scope {
        case .top:
            ranks[control] = mapped
            totals[control] = board.total
            mine[control] = board.me.map { toBoardPlayer($0, on: control, myAccount: myAccount) }
        case .around:
            aroundRanks[control] = mapped
            totals[control] = board.total
            mine[control] = board.me.map { toBoardPlayer($0, on: control, myAccount: myAccount) }
        case .friends:
            friendRanks[control] = mapped
            friendTotals[control] = board.total
            friendMine[control] = board.me.map { toBoardPlayer($0, on: control, myAccount: myAccount) }
        }
        rebuildEveryone()
    }

    func search(query: String, on control: TimeControl, using service: OnlineService) async -> [BoardPlayer] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, service.isSignedIn else { return [] }
        let myAccount = service.account ?? ""
        guard let found = await service.searchPlayers(alias: trimmed), !found.isEmpty else { return [] }
        let missingIDs = found.map(\.id).filter { latest[$0] == nil }
        let fetchedRecords = missingIDs.isEmpty ? [:] : (await service.records(minutes: control.minutes, ids: missingIDs) ?? [:])
        return found.map { entry in
            if let existing = latest[entry.id] {
                return existing
            }
            let detail = fetchedRecords[entry.id]
            let rec = detail?.record
            let hasGames = (rec?.games ?? 0) > 0
            return BoardPlayer(
                id: entry.id,
                alias: entry.alias,
                rank: nil,
                rating: hasGames ? rec?.rating : nil,
                clock: hasGames ? control : nil,
                lastSeen: rec?.lastPlayed ?? .distantPast,
                isLocal: entry.id == myAccount,
                key: entry.id
            )
        }
    }

    func refreshPresence(using service: OnlineService) async {
        guard let online = await service.online() else { return }
        presenceByKey = online
        var mergedPresence: [String: PresenceStatus] = online
        for (key, status) in online {
            if let mappedID = playerIDsByKey[key] {
                mergedPresence[mappedID] = status
            }
        }
        presence = mergedPresence

        var counts: [TimeControl: Int] = [:]
        for control in TimeControl.allCases {
            let myKey = service.account
            counts[control] = online.reduce(into: 0) { sum, pair in
                if pair.key != myKey, pair.value == .looking(control) {
                    sum += 1
                }
            }
        }
        lookingNow = counts

        // Resolve nicknames for any currently online accounts not yet seen on a rank list.
        let myAccount = service.account ?? ""
        let unknownIDs = online.keys.filter { $0 != myAccount && latest[$0] == nil }
        if !unknownIDs.isEmpty, let resolved = await service.records(minutes: 5, ids: Array(unknownIDs)) {
            for (id, entry) in resolved where !entry.alias.isEmpty {
                let hasGames = entry.record.games > 0
                latest[id] = BoardPlayer(
                    id: id,
                    alias: entry.alias,
                    rank: nil,
                    rating: hasGames ? entry.record.rating : nil,
                    clock: hasGames ? .five : nil,
                    lastSeen: entry.record.lastPlayed ?? Date(),
                    isLocal: id == myAccount,
                    key: id
                )
            }
            rebuildEveryone()
        }
    }

    func refreshLooking(using service: OnlineService? = nil) async {
        if let service, service.isSignedIn {
            await refreshPresence(using: service)
        }
    }

    // MARK: - Friends

    func refreshFriends(using service: OnlineService, askingGameCenter: Bool = false) async -> [FriendInvite] {
        var offers: [FriendInvite] = []
        let myAccount = service.account ?? ""
        if let list = await service.friends() {
            take(list, myAccount: myAccount)
            offers = list.invites
        }
        #if canImport(GameKit)
        if GKLocalPlayer.local.isAuthenticated,
           let status = try? await GKLocalPlayer.local.loadFriendsAuthorizationStatus(),
           status == .authorized || (status == .notDetermined && askingGameCenter),
           let theirs = try? await GKLocalPlayer.local.loadFriends() {
            let ours = Set((friends + incoming + outgoing).compactMap(\.key))
            gameCenterFriends = theirs.map(knownGameCenterPlayer).filter { !ours.contains($0.key ?? "") }.sorted(by: byName)
        }
        #endif
        return offers
    }

    private func take(_ list: OnlineFriends, myAccount: String) {
        friendsSnapshot = list
        friends = list.friends.map { person($0, myAccount: myAccount) }.sorted(by: byName)
        incoming = list.incoming.map { person($0, myAccount: myAccount) }.sorted(by: byName)
        outgoing = list.outgoing.map { person($0, myAccount: myAccount) }.sorted(by: byName)
        let ours = Set((friends + incoming + outgoing).compactMap(\.key))
        gameCenterFriends.removeAll { ours.contains($0.key ?? "") }
    }

    private func person(_ entry: OnlinePlayer, myAccount: String) -> BoardPlayer {
        if let met = latest[entry.id] {
            var copy = met
            copy.key = entry.id
            return copy
        }
        #if canImport(GameKit)
        if let gcID = playerIDsByKey[entry.id], let gkPlayer = players[gcID] {
            return knownGameCenterPlayer(gkPlayer)
        }
        #endif
        let hasGames = entry.record.games > 0
        return BoardPlayer(
            id: entry.id,
            alias: entry.alias,
            rank: nil,
            rating: hasGames ? entry.record.rating : nil,
            clock: nil,
            lastSeen: entry.record.lastPlayed ?? .distantPast,
            isLocal: entry.id == myAccount,
            key: entry.id
        )
    }

    func befriend(_ player: BoardPlayer, using service: OnlineService) async {
        guard let key = player.key else { return }
        if friendState(of: player) == .askedBy {
            _ = await service.accept(key)
        } else {
            _ = await service.request(key)
        }
        _ = await refreshFriends(using: service)
    }

    func unfriend(_ player: BoardPlayer, using service: OnlineService) async {
        guard let key = player.key else { return }
        _ = await service.remove(key)
        _ = await refreshFriends(using: service)
    }

    // MARK: - Immediate Post-Game Update & Game Center Mirroring

    func show(game control: TimeControl, mine record: OnlineRecord, account: String?, alias: String) {
        guard let account, !account.isEmpty else { return }
        var list = ranks[control] ?? []
        if let at = list.firstIndex(where: { $0.id == account || $0.isLocal }) {
            list.remove(at: at)
        } else {
            totals[control, default: 0] += 1
        }
        list.append(BoardPlayer(
            id: account,
            alias: alias,
            rank: nil,
            rating: record.rating,
            clock: control,
            lastSeen: record.lastPlayed ?? Date(),
            isLocal: true,
            key: account
        ))
        list.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        list = list.enumerated().map { index, p in
            BoardPlayer(
                id: p.id, alias: p.alias, rank: index + 1, rating: p.rating,
                clock: p.clock, lastSeen: p.lastSeen, isLocal: p.isLocal, key: p.key
            )
        }
        ranks[control] = list
        mine[control] = list.first(where: \.isLocal)
        if let localEntry = mine[control] {
            latest[account] = localEntry
            rebuildEveryone()
        }
    }

    func reset() {
        ranks = [:]
        aroundRanks = [:]
        friendRanks = [:]
        mine = [:]
        friendMine = [:]
        totals = [:]
        friendTotals = [:]
        everyone = []
        friends = []
        incoming = []
        outgoing = []
        latest = [:]
        presence = [:]
        presenceByKey = [:]
        lookingNow = [:]
        hasLoaded = false
    }

    /// Best-effort write of a rated game's new record to Apple's Game Center leaderboard.
    func submit(_ record: OnlineRecord, for control: TimeControl) async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        try? await GKLeaderboard.submitScore(
            record.rating,
            context: record.context,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID(control)]
        )
        #endif
    }

    /// Reads this player's existing Game Center leaderboard record on `control`
    /// for one-off rating carry-over (`POST /rating/import`). Returns `nil` if
    /// the player has never appeared on that Game Center leaderboard.
    func gameCenterRecord(on control: TimeControl) async -> OnlineRecord? {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated,
              let board = try? await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID(control)]).first,
              let (local, _) = try? await board.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime),
              let local, local.isOnTheList
        else { return nil }
        var record = OnlineRecord(score: local.score, context: local.context)
        if record.games == 0 {
            record.games = 1
        }
        if record.lastPlayed == nil {
            record.lastPlayed = local.date
        }
        return record
        #else
        return nil
        #endif
    }

    func loadPhoto(for id: String) async {
        #if canImport(GameKit) && canImport(UIKit)
        guard photos[id] == nil, let player = players[id],
              let image = try? await player.loadPhoto(for: .small) else { return }
        photos[id] = Image(uiImage: image)
        #endif
    }

    // MARK: - Helpers

    private func absorb(_ entries: [OnlinePlayer], on control: TimeControl, myAccount: String) -> [BoardPlayer] {
        entries.map { entry in
            let mapped = toBoardPlayer(entry, on: control, myAccount: myAccount)
            if (latest[mapped.id]?.lastSeen ?? .distantPast) <= mapped.lastSeen {
                latest[mapped.id] = mapped
            }
            return mapped
        }
    }

    private func toBoardPlayer(_ entry: OnlinePlayer, on control: TimeControl, myAccount: String) -> BoardPlayer {
        BoardPlayer(
            id: entry.id,
            alias: entry.alias,
            rank: entry.rank,
            rating: entry.record.rating,
            clock: control,
            lastSeen: entry.record.lastPlayed ?? .distantPast,
            isLocal: !myAccount.isEmpty && entry.id == myAccount,
            key: entry.id
        )
    }

    private func rebuildEveryone() {
        everyone = latest.values.sorted {
            if $0.lastSeen != $1.lastSeen { return $0.lastSeen > $1.lastSeen }
            return ($0.rating ?? 0) > ($1.rating ?? 0)
        }
    }

    private func byName(_ a: BoardPlayer, _ b: BoardPlayer) -> Bool {
        a.alias.localizedStandardCompare(b.alias) == .orderedAscending
    }

    #if canImport(GameKit)
    private func knownGameCenterPlayer(_ player: GKPlayer) -> BoardPlayer {
        let key = OnlineService.key(teamPlayerID: player.teamPlayerID)
        players[player.gamePlayerID] = player
        players[key] = player
        playerIDsByKey[key] = player.gamePlayerID
        let listed = latest[key] ?? latest[player.gamePlayerID]
        return BoardPlayer(
            id: listed?.id ?? player.gamePlayerID,
            alias: listed?.alias ?? player.alias,
            rank: listed?.rank,
            rating: listed?.rating,
            clock: listed?.clock,
            lastSeen: listed?.lastSeen ?? .distantPast,
            isLocal: false,
            key: key
        )
    }
    #endif

    #if DEBUG
    func fillWithSamples(now: Date = Date()) {
        let names = ["Marta K.", "nimzo_fan", "Theo", "rook_lift", "Ana P.", "Kasparov2029", "lena",
                     "d4_d5", "Oscar", "pawnstorm", "Yuki", "B. Harmon", "castle_long", "Ivo"]
        let hours: [Double] = [0.2, 3, 9, 26, 40, 70, 100, 150, 200, 260, 400, 700, 900, 1500]
        var list: [BoardPlayer] = []
        for (i, name) in names.enumerated() {
            let key = String(format: "%032x", i + 1)
            list.append(BoardPlayer(
                id: key, alias: name, rank: i + 1, rating: 1890 - i * 47 - (i % 3) * 11,
                clock: .five, lastSeen: now.addingTimeInterval(-hours[i] * 3600), isLocal: false,
                key: key
            ))
        }
        let me = BoardPlayer(id: "local", alias: L.t("common.you", "You"), rank: 6, rating: 1655, clock: .five,
                             lastSeen: now, isLocal: true)
        list.insert(me, at: 5)
        list = list.enumerated().map { i, p in
            BoardPlayer(id: p.id, alias: p.alias, rank: i + 1, rating: p.rating, clock: p.clock,
                        lastSeen: p.lastSeen, isLocal: p.isLocal, key: p.key)
        }
        for control in TimeControl.allCases {
            ranks[control] = list
            aroundRanks[control] = list
            totals[control] = list.count
            mine[control] = list.first(where: \.isLocal)
            lookingNow[control] = control == .five ? 3 : control == .three ? 1 : 0
        }
        latest = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        everyone = list.sorted { $0.lastSeen > $1.lastSeen }
        recent = Array(list.filter { !$0.isLocal }.prefix(2))
        let friendIDs: Set<String> = [String(format: "%032x", 2), String(format: "%032x", 5), String(format: "%032x", 10)]
        friends = list.filter { friendIDs.contains($0.id) }
        friendRanks[.five] = friends
        friendTotals[.five] = friends.count
        let inKey = String(repeating: "a", count: 32)
        incoming = [BoardPlayer(id: inKey, alias: "queen_side", rank: nil, rating: nil, clock: nil,
                                lastSeen: .distantPast, isLocal: false, key: inKey)]
        outgoing = list.filter { $0.id == String(format: "%032x", 7) }
        let gcKey = String(repeating: "b", count: 32)
        gameCenterFriends = [BoardPlayer(id: gcKey, alias: "Mira", rank: nil, rating: nil, clock: nil,
                                         lastSeen: .distantPast, isLocal: false, key: gcKey)]
        let p0 = String(format: "%032x", 1)
        let p1 = String(format: "%032x", 2)
        let p3 = String(format: "%032x", 4)
        presenceByKey = [p0: .looking(.five), p1: .online, p3: .playing(.ten)]
        presence = presenceByKey
        hasLoaded = true
    }
    #endif
}

#if canImport(GameKit)
private extension GKLeaderboard.Entry {
    var isOnTheList: Bool { rank > 0 }
}
#endif

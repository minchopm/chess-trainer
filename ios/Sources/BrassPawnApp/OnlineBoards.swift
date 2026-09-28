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

/// Somebody on the rank list, or among the players: their Game Center nickname,
/// where they stand on a clock, and when Game Center last heard from them.
struct BoardPlayer: Identifiable, Equatable {
    /// The Game Center player ID, which is what an invitation is addressed to.
    let id: String
    let alias: String
    /// Their place on the clock asked about, where they are on it.
    let rank: Int?
    let rating: Int?
    /// The clock `rating` is on — for the players list, the one they played last.
    let clock: TimeControl?
    let lastSeen: Date
    let isLocal: Bool
    /// Their key in `OnlineService`, where known: what a friend request, and
    /// who is online, go by.
    var key: String? = nil

    func isActive(at now: Date = Date()) -> Bool {
        now.timeIntervalSince(lastSeen) < OnlineBoards.activeWindow
    }
}

/// The rank lists and the players, read from Game Center.
///
/// Everything here is Game Center's, apart from who is online this minute.
/// Each clock has its own leaderboard, and a player's rating on it is the most
/// recent one their own device wrote there at the end of a rated game — see
/// `OnlineRecord` — a rating, unlike a high score, is meant to go down as well
/// as up. The same entry says when it was sent, which is the whole of
/// "active": seen in the last week, or not. Who has the app on screen right
/// now Game Center cannot say, so that comes from `OnlineService`, for the players
/// who show it; how many are looking for a game on each clock, it can.
@MainActor
@Observable
final class OnlineBoards {
    /// How recently somebody has to have been seen to count as active.
    nonisolated static let activeWindow: TimeInterval = 7 * 86_400
    /// How much of a list is read at a time: a page, and the next one when the
    /// list is scrolled to its end. The lists say how many there are in all.
    static let pageSize = 100
    /// How far a search reads before it gives up on finding somebody.
    static let searchLimit = 2_000

    static func leaderboardID(_ control: TimeControl) -> String {
        "brasspawn.online.\(control.minutes)"
    }

    private(set) var ranks: [TimeControl: [BoardPlayer]] = [:]
    /// Where this player stands on each clock, if they are on it.
    private(set) var mine: [TimeControl: BoardPlayer] = [:]
    private(set) var totals: [TimeControl: Int] = [:]
    /// Everybody on any clock, once each, the most recently seen first.
    private(set) var everyone: [BoardPlayer] = []
    /// The people this player has played lately, from Game Center's own record.
    private(set) var recent: [BoardPlayer] = []
    /// This player's friends — ours, asked for and accepted in the app. A
    /// friend is a player too, and shows in both lists.
    private(set) var friends: [BoardPlayer] = []
    /// Requests to this player, and from it, not yet answered.
    private(set) var incoming: [BoardPlayer] = []
    private(set) var outgoing: [BoardPlayer] = []
    /// Game Center friends who play and are not friends here yet: a request
    /// away. Read once the player lets the app see them.
    private(set) var gameCenterFriends: [BoardPlayer] = []
    enum FriendState { case none, friend, asked, askedBy }
    /// The service's last word on the friends, kept to be matched again with
    /// the players once the lists have been read.
    private var friendsList: FriendsList?
    /// Every player met on any list, once each, as last seen.
    private var latest: [String: BoardPlayer] = [:]
    private var loadingMore: Set<TimeControl> = []
    /// How many are looking for a game on each clock right now.
    private(set) var lookingNow: [TimeControl: Int] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var photos: [String: Image] = [:]

    #if canImport(GameKit)
    /// The players themselves, which is what an invitation is sent to.
    private var players: [String: GKPlayer] = [:]
    func player(_ id: String) -> GKPlayer? { players[id] }
    #endif

    /// Who is on screen right now, by Game Center player ID — of the players
    /// the lists and Game Center let this one see. From `OnlineService`, which
    /// hears it from each app that shows its player online.
    private(set) var presence: [String: PresenceStatus] = [:]
    /// Each player's key in `OnlineService`, to their Game Center player ID.
    private var playerIDs: [String: String] = [:]
    /// Who is online by key, whether or not the lists have met them.
    private var presenceByKey: [String: PresenceStatus] = [:]

    /// Everybody on screen now, looking for a game first.
    func onlineNow() -> [BoardPlayer] {
        var seen = Set<String>()
        return (everyone + recent + friends)
            .filter { !$0.isLocal && status(of: $0) != nil && seen.insert($0.id).inserted }
            .sorted { rank(status(of: $0)) < rank(status(of: $1)) }
    }

    private func rank(_ status: PresenceStatus?) -> Int {
        switch status {
        case .looking: 0
        case .online: 1
        case .playing: 2
        case nil: 3
        }
    }

    /// Whether a player can be invited from here: Game Center can send them
    /// an invitation, or they are a friend, who can be offered a game.
    func canInvite(_ player: BoardPlayer) -> Bool {
        #if canImport(GameKit)
        if players[player.id] != nil { return true }
        #endif
        return player.key != nil && friendState(of: player) == .friend
    }

    func friendState(of player: BoardPlayer) -> FriendState {
        let same = { (other: BoardPlayer) in other.id == player.id || (other.key != nil && other.key == player.key) }
        if friends.contains(where: same) { return .friend }
        if outgoing.contains(where: same) { return .asked }
        if incoming.contains(where: same) { return .askedBy }
        return .none
    }

    /// What somebody is doing now, if they are online: by Game Center player
    /// ID where the lists have met them, by key for a friend they have not.
    func status(of player: BoardPlayer) -> PresenceStatus? {
        presence[player.id] ?? player.key.flatMap { presenceByKey[$0] }
    }

    /// Whether a clock's list has more than has been read of it.
    func hasMore(on control: TimeControl) -> Bool {
        (ranks[control]?.count ?? 0) < (totals[control] ?? 0)
    }

    func active(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && status(of: $0) == nil && $0.isActive(at: now) }
    }

    func inactive(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && status(of: $0) == nil && !$0.isActive(at: now) }
    }

    /// Who is on screen, asked again: whenever the players are looked at, and
    /// every minute while they are.
    func refreshPresence(using service: OnlineService) async {
        guard let online = await service.online() else { return }
        presenceByKey = online
        presence = Dictionary(
            online.compactMap { key, status in playerIDs[key].map { ($0, status) } },
            uniquingKeysWith: { a, _ in a }
        )
    }

    /// This player's record on one clock, written to its leaderboard — the
    /// only place an online rating is kept.
    func submit(_ record: OnlineRecord, for control: TimeControl) async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        try? await GKLeaderboard.submitScore(
            record.rating, context: record.context, player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID(control)]
        )
        #endif
    }

    #if canImport(GameKit)
    /// Game Center's records of these players on one clock: this one's own,
    /// and whoever else is asked about. Somebody it has none for is new there.
    /// Nil when Game Center could not be asked.
    func records(on control: TimeControl, of others: [GKPlayer]) async
        -> (mine: OnlineRecord, others: [String: OnlineRecord])? {
        guard GKLocalPlayer.local.isAuthenticated,
              let board = try? await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID(control)]).first,
              let (local, entries) = try? await board.loadEntries(for: [GKLocalPlayer.local] + others, timeScope: .allTime)
        else { return nil }
        var found: [String: OnlineRecord] = [:]
        for entry in entries where entry.isOnTheList {
            found[entry.player.gamePlayerID] = OnlineRecord(score: entry.score, context: entry.context)
        }
        // No entry of one's own — not yet played on this clock — is a new
        // player's record, not a rating of nought.
        let mine = local.flatMap { $0.isOnTheList ? OnlineRecord(score: $0.score, context: $0.context) : nil }
            ?? found[GKLocalPlayer.local.gamePlayerID] ?? .new
        return (mine, found)
    }
    #endif

    /// Read everything afresh: the first page of every clock's list, the
    /// players, the friends, the recent opponents and how many are waiting on
    /// each clock.
    func refresh() async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated, !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        let localID = GKLocalPlayer.local.gamePlayerID
        let boards = (try? await GKLeaderboard.loadLeaderboards(
            IDs: TimeControl.allCases.map(Self.leaderboardID)
        )) ?? []
        latest = [:]
        for control in TimeControl.allCases {
            guard let board = boards.first(where: { $0.baseLeaderboardID == Self.leaderboardID(control) }),
                  let (local, entries, total) = try? await board.loadEntries(
                      for: .global, timeScope: .allTime, range: NSRange(location: 1, length: Self.pageSize)
                  )
            else { continue }
            ranks[control] = absorb(entries, on: control, localID: localID)
            totals[control] = total
            mine[control] = local.flatMap {
                guard $0.isOnTheList else { return nil }
                return BoardPlayer(id: localID, alias: GKLocalPlayer.local.alias, rank: $0.rank, rating: $0.score,
                                   clock: control, lastSeen: $0.date, isLocal: true)
            }
        }
        everyone = latest.values.sorted { $0.lastSeen > $1.lastSeen }

        if let played = try? await GKLocalPlayer.local.loadRecentPlayers() {
            recent = played.prefix(12).map(known)
        }
        // Friends read before the lists were are the players on them now.
        if let friendsList { take(friendsList) }
        await refreshLooking()
        #endif
    }

    /// The next page of a clock's list, when the list is scrolled to its end.
    func loadMore(on control: TimeControl) async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated, hasMore(on: control), !loadingMore.contains(control) else { return }
        loadingMore.insert(control)
        defer { loadingMore.remove(control) }
        let from = (ranks[control]?.count ?? 0) + 1
        guard let board = try? await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID(control)]).first,
              let (_, entries, total) = try? await board.loadEntries(
                  for: .global, timeScope: .allTime, range: NSRange(location: from, length: Self.pageSize)
              )
        else { return }
        let more = absorb(entries, on: control, localID: GKLocalPlayer.local.gamePlayerID)
        let have = Set((ranks[control] ?? []).map(\.id))
        ranks[control, default: []] += more.filter { !have.contains($0.id) }
        totals[control] = total
        everyone = latest.values.sorted { $0.lastSeen > $1.lastSeen }
        #endif
    }

    /// Read on until the whole of a clock's list is here, or the search limit:
    /// Game Center cannot look a nickname up, so a search reads the list.
    func loadEverything(on control: TimeControl) async {
        while hasMore(on: control), (ranks[control]?.count ?? 0) < Self.searchLimit {
            let before = ranks[control]?.count ?? 0
            await loadMore(on: control)
            if (ranks[control]?.count ?? 0) == before { break }
        }
    }

    #if canImport(GameKit)
    /// Entries turned into players, each remembered — for an invitation, for
    /// who is online, and for the list of everybody.
    private func absorb(_ entries: [GKLeaderboard.Entry], on control: TimeControl, localID: String) -> [BoardPlayer] {
        entries.filter(\.isOnTheList).map { entry -> BoardPlayer in
            players[entry.player.gamePlayerID] = entry.player
            playerIDs[OnlineService.key(teamPlayerID: entry.player.teamPlayerID)] = entry.player.gamePlayerID
            let player = BoardPlayer(
                id: entry.player.gamePlayerID, alias: entry.player.alias,
                rank: entry.rank, rating: entry.score, clock: control,
                lastSeen: entry.date, isLocal: entry.player.gamePlayerID == localID,
                key: OnlineService.key(teamPlayerID: entry.player.teamPlayerID)
            )
            if (latest[player.id]?.lastSeen ?? .distantPast) < player.lastSeen { latest[player.id] = player }
            return player
        }
    }

    /// A player known from Game Center — a friend, a recent opponent — with
    /// what the lists say of them, if anything.
    private func known(_ player: GKPlayer) -> BoardPlayer {
        players[player.gamePlayerID] = player
        playerIDs[OnlineService.key(teamPlayerID: player.teamPlayerID)] = player.gamePlayerID
        let listed = latest[player.gamePlayerID]
        return BoardPlayer(
            id: player.gamePlayerID, alias: player.alias, rank: listed?.rank,
            rating: listed?.rating, clock: listed?.clock,
            lastSeen: listed?.lastSeen ?? .distantPast, isLocal: false,
            key: OnlineService.key(teamPlayerID: player.teamPlayerID)
        )
    }
    #endif

    /// The friends, the requests both ways and the games offered, from the
    /// service; and, once the player lets the app see them, the Game Center
    /// friends who play, as people to ask. Game Center asks that the first
    /// time the friends are looked at.
    func refreshFriends(using service: OnlineService, askingGameCenter: Bool = false) async -> [FriendInvite] {
        var offers: [FriendInvite] = []
        if let list = await service.friends() {
            take(list)
            offers = list.invites
        }
        #if canImport(GameKit)
        if GKLocalPlayer.local.isAuthenticated,
           let status = try? await GKLocalPlayer.local.loadFriendsAuthorizationStatus(),
           status == .authorized || (status == .notDetermined && askingGameCenter),
           let theirs = try? await GKLocalPlayer.local.loadFriends() {
            let ours = Set((friends + incoming + outgoing).compactMap(\.key))
            gameCenterFriends = theirs.map(known).filter { !ours.contains($0.key ?? "") }.sorted(by: byName)
        }
        #endif
        return offers
    }

    private func take(_ list: FriendsList) {
        friendsList = list
        friends = list.friends.map(person).sorted(by: byName)
        incoming = list.incoming.map(person).sorted(by: byName)
        outgoing = list.outgoing.map(person).sorted(by: byName)
        let ours = Set((friends + incoming + outgoing).compactMap(\.key))
        gameCenterFriends.removeAll { ours.contains($0.key ?? "") }
    }

    private func byName(_ a: BoardPlayer, _ b: BoardPlayer) -> Bool {
        a.alias.localizedStandardCompare(b.alias) == .orderedAscending
    }

    /// Somebody the service names by key: the player the lists have met, if
    /// they have — with a rating, a picture, and an invitation Game Center can
    /// deliver — or else the nickname they gave.
    private func person(_ entry: FriendsList.Entry) -> BoardPlayer {
        if let id = playerIDs[entry.id], let met = latest[id] ?? recent.first(where: { $0.id == id }) {
            var known = met
            known.key = entry.id
            return known
        }
        #if canImport(GameKit)
        if let id = playerIDs[entry.id], let player = players[id] { return known(player) }
        #endif
        return BoardPlayer(id: "key:\(entry.id)", alias: entry.alias, rank: nil, rating: nil, clock: nil,
                           lastSeen: .distantPast, isLocal: false, key: entry.id)
    }

    /// Ask somebody to be friends — or say yes to them, if they asked.
    func befriend(_ player: BoardPlayer, using service: OnlineService) async {
        guard let key = player.key else { return }
        if friendState(of: player) == .askedBy {
            _ = await service.accept(key)
        } else {
            _ = await service.request(key, alias: player.alias)
        }
        _ = await refreshFriends(using: service)
    }

    /// No longer friends, a request declined, or one taken back.
    func unfriend(_ player: BoardPlayer, using service: OnlineService) async {
        guard let key = player.key else { return }
        _ = await service.remove(key)
        _ = await refreshFriends(using: service)
    }

    /// A rated game just played, on the lists at once. Game Center takes a
    /// minute or two to hand a new score back, and both devices worked out
    /// both new ratings from the same two records — so both go in now, and the
    /// lists are read again once Game Center has caught up.
    func show(game control: TimeControl, mine record: OnlineRecord, opponent: (id: String, record: OnlineRecord)?) {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let localID = GKLocalPlayer.local.gamePlayerID
        var list = ranks[control] ?? []
        func place(_ id: String, _ alias: String, _ rating: Int, isLocal: Bool) {
            if let at = list.firstIndex(where: { $0.id == id }) { list.remove(at: at) } else if isLocal || players[id] != nil {
                totals[control, default: 0] += 1
            }
            list.append(BoardPlayer(id: id, alias: alias, rank: nil, rating: rating, clock: control,
                                    lastSeen: Date(), isLocal: isLocal,
                                    key: players[id].map { OnlineService.key(teamPlayerID: $0.teamPlayerID) }))
        }
        place(localID, GKLocalPlayer.local.alias, record.rating, isLocal: true)
        if let opponent, let player = players[opponent.id] {
            place(opponent.id, player.alias, opponent.record.rating, isLocal: false)
        }
        list.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        list = list.enumerated().map { index, player in
            BoardPlayer(id: player.id, alias: player.alias, rank: index + 1, rating: player.rating,
                        clock: player.clock, lastSeen: player.lastSeen, isLocal: player.isLocal, key: player.key)
        }
        ranks[control] = list
        mine[control] = list.first(where: \.isLocal)
        for player in list where player.lastSeen > (latest[player.id]?.lastSeen ?? .distantPast) {
            latest[player.id] = player
        }
        everyone = latest.values.sorted { $0.lastSeen > $1.lastSeen }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(45))
            await self?.refresh()
            try? await Task.sleep(for: .seconds(120))
            await self?.refresh()
        }
        #endif
    }

    /// How many are looking for a game on each clock — cheap, and worth asking
    /// again whenever the lobby is looked at.
    func refreshLooking() async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        for control in TimeControl.allCases {
            if let count = try? await GKMatchmaker.shared().queryPlayerGroupActivity(control.playerGroup) {
                lookingNow[control] = count
            }
        }
        #endif
    }

    /// A player's Game Center picture, loaded once, when their row is shown.
    func loadPhoto(for id: String) async {
        #if canImport(GameKit) && canImport(UIKit)
        guard photos[id] == nil, let player = players[id],
              let image = try? await player.loadPhoto(for: .small) else { return }
        photos[id] = Image(uiImage: image)
        #endif
    }

    #if DEBUG
    /// Invented players for looking at the screens on a simulator, where Game
    /// Center will not sign in. Never in a release build.
    func fillWithSamples(now: Date = Date()) {
        let names = ["Marta K.", "nimzo_fan", "Theo", "rook_lift", "Ana P.", "Kasparov2029", "lena",
                     "d4_d5", "Oscar", "pawnstorm", "Yuki", "B. Harmon", "castle_long", "Ivo"]
        let hours: [Double] = [0.2, 3, 9, 26, 40, 70, 100, 150, 200, 260, 400, 700, 900, 1500]
        var list: [BoardPlayer] = []
        for (i, name) in names.enumerated() {
            list.append(BoardPlayer(
                id: "sample-\(i)", alias: name, rank: i + 1, rating: 1890 - i * 47 - (i % 3) * 11,
                clock: .five, lastSeen: now.addingTimeInterval(-hours[i] * 3600), isLocal: false,
                key: String(format: "%032x", i + 1)
            ))
        }
        let me = BoardPlayer(id: "local", alias: "You", rank: 6, rating: 1655, clock: .five,
                             lastSeen: now, isLocal: true)
        list.insert(me, at: 5)
        list = list.enumerated().map { i, p in
            BoardPlayer(id: p.id, alias: p.alias, rank: i + 1, rating: p.rating, clock: p.clock,
                        lastSeen: p.lastSeen, isLocal: p.isLocal, key: p.key)
        }
        for control in TimeControl.allCases {
            ranks[control] = list
            totals[control] = list.count
            mine[control] = list.first(where: \.isLocal)
            lookingNow[control] = control == .five ? 3 : control == .three ? 1 : 0
        }
        everyone = list.sorted { $0.lastSeen > $1.lastSeen }
        recent = Array(list.filter { !$0.isLocal }.prefix(2))
        friends = list.filter { ["sample-1", "sample-4", "sample-9"].contains($0.id) }
        incoming = [BoardPlayer(id: "key:sample-in", alias: "queen_side", rank: nil, rating: nil, clock: nil,
                                lastSeen: .distantPast, isLocal: false, key: String(repeating: "a", count: 32))]
        outgoing = list.filter { $0.id == "sample-6" }
        gameCenterFriends = [BoardPlayer(id: "sample-gc", alias: "Mira", rank: nil, rating: nil, clock: nil,
                                         lastSeen: .distantPast, isLocal: false, key: String(repeating: "b", count: 32))]
        presence = ["sample-0": .looking(.five), "sample-1": .online, "sample-3": .playing(.ten)]
        hasLoaded = true
    }
    #endif
}

#if canImport(GameKit)
private extension GKLeaderboard.Entry {
    /// Whether this is an entry at all. For a player who has sent nothing to a
    /// list, Game Center still hands back an entry of their own — rank 0, an
    /// anonymous player with no ID, no score, no date — and its `date` and
    /// `player`, which Swift is told can never be nil, stop the app the moment
    /// they are read. The rank is a plain number, and says which it is.
    var isOnTheList: Bool { rank > 0 }
}
#endif

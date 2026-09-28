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

    func isActive(at now: Date = Date()) -> Bool {
        now.timeIntervalSince(lastSeen) < OnlineBoards.activeWindow
    }
}

/// The rank lists and the players.
///
/// The numbers are the referee's (`Referee`): each clock's list is a file it
/// publishes, in its own order, and no device's word for its own rating is
/// taken. Game Center says who the people on it are — nickname, picture, the
/// handle an invitation is sent to, as each player lets them be shown — and
/// when it last heard from them, which is the whole of "active": seen in the
/// last week, or not. Game Center's own leaderboards are sent the rating the
/// referee settled on; what they hold is only ever used to find the player,
/// never for the number. Game Center cannot say who has the app open this
/// minute, and nothing here pretends to; what it can say is how many people
/// are looking for a game on each clock right now, and that is shown too.
@MainActor
@Observable
final class OnlineBoards {
    /// How recently somebody has to have been seen to count as active.
    nonisolated static let activeWindow: TimeInterval = 7 * 86_400
    /// How much of each Game Center list is read to find the players on the
    /// referee's: pages of a hundred. Plenty for the app's size.
    static let pageSize = 100
    static let pages = 3

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
    /// the lists and Game Center let this one see. From the referee, which
    /// hears it from each app that shows its player online.
    private(set) var presence: [String: PresenceStatus] = [:]
    /// The referee's key for each player met, to its Game Center player ID.
    private var playerIDs: [String: String] = [:]

    /// Everybody on screen now, looking for a game first.
    func onlineNow() -> [BoardPlayer] {
        var seen = Set<String>()
        return (everyone + recent)
            .filter { !$0.isLocal && presence[$0.id] != nil && seen.insert($0.id).inserted }
            .sorted { rank(presence[$0.id]) < rank(presence[$1.id]) }
    }

    private func rank(_ status: PresenceStatus?) -> Int {
        switch status {
        case .looking: 0
        case .online: 1
        case .playing: 2
        case nil: 3
        }
    }

    func active(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && presence[$0.id] == nil && $0.isActive(at: now) }
    }

    func inactive(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && presence[$0.id] == nil && !$0.isActive(at: now) }
    }

    /// Who is on screen, asked again: whenever the players are looked at, and
    /// every minute while they are.
    func refreshPresence(using referee: Referee) async {
        guard let online = await referee.online() else { return }
        presence = Dictionary(
            online.compactMap { key, status in playerIDs[key].map { ($0, status) } },
            uniquingKeysWith: { a, _ in a }
        )
    }

    /// This player's rating on one clock, sent to its leaderboard.
    func submit(rating: Int, for control: TimeControl) async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated else { return }
        try? await GKLeaderboard.submitScore(
            rating, context: 0, player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID(control)]
        )
        #endif
    }

    /// The referee's lists, as last read.
    private(set) var standings: [TimeControl: Standings] = [:]

    /// Read everything: every clock's list, the players, the recent opponents
    /// and how many are waiting on each clock. `fresh` is the referee's lists
    /// when they have just been read; otherwise they are read here.
    func refresh(standings fresh: [TimeControl: Standings]? = nil) async {
        #if canImport(GameKit)
        guard GKLocalPlayer.local.isAuthenticated, !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        if let fresh {
            standings.merge(fresh) { $1 }
        } else {
            for control in TimeControl.allCases {
                if let list = await Referee.standings(control) { standings[control] = list }
            }
        }
        let localID = GKLocalPlayer.local.gamePlayerID
        let localKey = Referee.key(teamPlayerID: GKLocalPlayer.local.teamPlayerID)
        let boards = (try? await GKLeaderboard.loadLeaderboards(
            IDs: TimeControl.allCases.map(Self.leaderboardID)
        )) ?? []
        var latest: [String: BoardPlayer] = [:]
        for control in TimeControl.allCases {
            // Who is who, from Game Center: a few pages of it, since its order
            // is not the one that counts.
            var entries: [GKLeaderboard.Entry] = []
            if let board = boards.first(where: { $0.baseLeaderboardID == Self.leaderboardID(control) }) {
                for page in 0..<Self.pages {
                    guard let (_, some, _) = try? await board.loadEntries(
                        for: .global, timeScope: .allTime,
                        range: NSRange(location: 1 + page * Self.pageSize, length: Self.pageSize)
                    ) else { break }
                    entries += some
                    if some.count < Self.pageSize { break }
                }
            }
            var known: [String: GKLeaderboard.Entry] = [:]
            for entry in entries {
                players[entry.player.gamePlayerID] = entry.player
                playerIDs[Referee.key(teamPlayerID: entry.player.teamPlayerID)] = entry.player.gamePlayerID
                known[Referee.key(teamPlayerID: entry.player.teamPlayerID)] = known[Referee.key(teamPlayerID: entry.player.teamPlayerID)] ?? entry
            }
            guard let list = standings[control]?.players else { continue }
            let place = Dictionary(list.enumerated().map { ($1.id, ($0 + 1, $1.rating)) }, uniquingKeysWith: { a, _ in a })
            // The referee's order, of the players Game Center lets this one see.
            ranks[control] = list.enumerated().compactMap { index, standing in
                guard let entry = known[standing.id] else { return nil }
                return BoardPlayer(
                    id: entry.player.gamePlayerID, alias: entry.player.alias,
                    rank: index + 1, rating: standing.rating, clock: control,
                    lastSeen: entry.date, isLocal: standing.id == localKey
                )
            }
            totals[control] = list.count
            mine[control] = place[localKey].map { rank, rating in
                BoardPlayer(id: localID, alias: GKLocalPlayer.local.alias, rank: rank, rating: rating,
                            clock: control, lastSeen: known[localKey]?.date ?? Date(), isLocal: true)
            }
            for (key, entry) in known {
                let player = BoardPlayer(
                    id: entry.player.gamePlayerID, alias: entry.player.alias,
                    rank: place[key]?.0, rating: place[key]?.1, clock: control,
                    lastSeen: entry.date, isLocal: key == localKey
                )
                if (latest[player.id]?.lastSeen ?? .distantPast) < player.lastSeen { latest[player.id] = player }
            }
        }
        everyone = latest.values.sorted { $0.lastSeen > $1.lastSeen }

        if let played = try? await GKLocalPlayer.local.loadRecentPlayers() {
            recent = played.prefix(12).map { player in
                players[player.gamePlayerID] = player
                playerIDs[Referee.key(teamPlayerID: player.teamPlayerID)] = player.gamePlayerID
                let known = latest[player.gamePlayerID]
                return BoardPlayer(
                    id: player.gamePlayerID, alias: player.alias, rank: known?.rank,
                    rating: known?.rating, clock: known?.clock,
                    lastSeen: known?.lastSeen ?? .distantPast, isLocal: false
                )
            }
        }
        await refreshLooking()
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
                clock: .five, lastSeen: now.addingTimeInterval(-hours[i] * 3600), isLocal: false
            ))
        }
        let me = BoardPlayer(id: "local", alias: "You", rank: 6, rating: 1655, clock: .five,
                             lastSeen: now, isLocal: true)
        list.insert(me, at: 5)
        list = list.enumerated().map { i, p in
            BoardPlayer(id: p.id, alias: p.alias, rank: i + 1, rating: p.rating, clock: p.clock,
                        lastSeen: p.lastSeen, isLocal: p.isLocal)
        }
        for control in TimeControl.allCases {
            ranks[control] = list
            totals[control] = list.count
            mine[control] = list.first(where: \.isLocal)
            lookingNow[control] = control == .five ? 3 : control == .three ? 1 : 0
        }
        everyone = list.sorted { $0.lastSeen > $1.lastSeen }
        recent = Array(list.filter { !$0.isLocal }.prefix(2))
        presence = ["sample-0": .looking(.five), "sample-1": .online, "sample-3": .playing(.ten)]
        hasLoaded = true
    }
    #endif
}

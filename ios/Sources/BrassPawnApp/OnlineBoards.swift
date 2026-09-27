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

/// The rank list and the players, read from Game Center.
///
/// There is no server of ours behind this and there is not going to be one:
/// everything here is Game Center's. Each clock has its own leaderboard, and a
/// player's rating on it is the most recent one they sent — a rating, unlike a
/// high score, is meant to go down as well as up. The same entry says when it
/// was sent, which is the whole of "active": seen in the last week, or not.
/// Game Center cannot say who has the app open this minute, and nothing here
/// pretends to; what it can say is how many people are looking for a game on
/// each clock right now, and that is shown too.
@MainActor
@Observable
final class OnlineBoards {
    /// How recently somebody has to have been seen to count as active.
    nonisolated static let activeWindow: TimeInterval = 7 * 86_400
    /// How many of each list are read. Plenty for the app's size; the lists
    /// say how many there are in all.
    static let pageSize = 100

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

    func active(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && $0.isActive(at: now) }
    }

    func inactive(at now: Date = Date()) -> [BoardPlayer] {
        everyone.filter { !$0.isLocal && !$0.isActive(at: now) }
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

    /// Read everything: every clock's list, the players, the recent opponents
    /// and how many are waiting on each clock.
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
        var latest: [String: BoardPlayer] = [:]
        for control in TimeControl.allCases {
            guard let board = boards.first(where: { $0.baseLeaderboardID == Self.leaderboardID(control) }),
                  let (local, entries, total) = try? await board.loadEntries(
                      for: .global, timeScope: .allTime, range: NSRange(location: 1, length: Self.pageSize)
                  )
            else { continue }
            let listed = entries.map { entry -> BoardPlayer in
                players[entry.player.gamePlayerID] = entry.player
                return BoardPlayer(
                    id: entry.player.gamePlayerID, alias: entry.player.alias,
                    rank: entry.rank, rating: entry.score, clock: control,
                    lastSeen: entry.date, isLocal: entry.player.gamePlayerID == localID
                )
            }
            ranks[control] = listed
            totals[control] = total
            mine[control] = local.map {
                BoardPlayer(id: localID, alias: GKLocalPlayer.local.alias, rank: $0.rank, rating: $0.score,
                            clock: control, lastSeen: $0.date, isLocal: true)
            }
            for player in listed where (latest[player.id]?.lastSeen ?? .distantPast) < player.lastSeen {
                latest[player.id] = player
            }
        }
        everyone = latest.values.sorted { $0.lastSeen > $1.lastSeen }

        if let played = try? await GKLocalPlayer.local.loadRecentPlayers() {
            recent = played.prefix(12).map { player in
                players[player.gamePlayerID] = player
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
        hasLoaded = true
    }
    #endif
}

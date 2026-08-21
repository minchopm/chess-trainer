import Foundation
import Testing
@testable import ChessTraining

@Suite("Rating pools")
struct RatingPoolTests {
    /// A file written before the ratings were split still has to load, and the
    /// player still has to find their rating where they left it.
    @Test("A file from before the split keeps every rating it held")
    func migratesTheOldShape() throws {
        // A dictionary keyed by an enum is written by Swift as a flat array of
        // alternating keys and values, not as an object — so this is the shape
        // the old files are actually in.
        let old = """
        {
          "ratings": [ "tactics", 1740, "positional", 1310, "endgame", 980 ],
          "onlineRating": 1655,
          "onlineGames": 87,
          "onlineWins": 40, "onlineLosses": 39, "onlineDraws": 8,
          "currentStreak": 4, "bestStreak": 11
        }
        """
        let progress = try JSONDecoder().decode(TrainingProgress.self, from: Data(old.utf8))

        #expect(progress.rating(.tactics) == 1740)
        #expect(progress.rating(.positional) == 1310)
        #expect(progress.rating(.endgame) == 980)

        // The one online rating becomes five, one per clock: a rating earned at
        // five minutes is a better guess at somebody's three-minute strength
        // than 1200 is.
        for control in TimeControl.allCases {
            #expect(progress.rating(.online(minutes: control.minutes)) == 1655,
                    "\(control.minutes) min came out at \(progress.rating(.online(minutes: control.minutes)))")
            // But not the games. Each clock has to find its own level now, and
            // a count of eighty-seven would barely let it move.
            #expect(progress.gamesPlayed(.online(minutes: control.minutes)) == 0)
        }

        #expect(progress.onlineWins == 40)
        #expect(progress.bestStreak == 11)
    }

    /// The whole point: a result in one pool must not touch another.
    @Test("Clocks are rated apart from each other")
    func clocksDoNotMix() {
        var progress = TrainingProgress()
        let before = progress.rating(.online(minutes: 30))

        for _ in 0..<5 {
            progress.settle(.online(minutes: 3), against: 1600, score: 1)
        }

        #expect(progress.rating(.online(minutes: 3)) > 1200, "beating 1600s should move blitz")
        #expect(progress.rating(.online(minutes: 30)) == before, "and should not move classical")
        #expect(progress.rating(.training(.tactics)) == 1200)
        #expect(progress.rating(.engine) == 1200)
    }

    /// A rush run is rated per puzzle, in a pool of its own, and by length.
    @Test("A rush run rates only its own length")
    func rushRatesItsOwnLength() {
        var progress = TrainingProgress()
        progress.pools[RatedPool.training(.tactics).id] = PoolRating(rating: 1500)

        // Untouched, it starts from the tactics rating rather than from 1200:
        // a month of solving already says roughly how hard the first run is.
        #expect(progress.rating(.rush(minutes: 5)) == 1500)

        progress.record(
            rush: RushRecord(solved: 3, bestStreak: 3, duration: 300, achievedAt: Date()),
            attempts: (0..<3).map { _ in RushAttempt(rating: 1800, solved: true) }
        )

        #expect(progress.rating(.rush(minutes: 5)) > 1500)
        #expect(progress.rating(.rush(minutes: 3)) == 1500, "a different length is a different pool")
        #expect(progress.rating(.training(.tactics)) == 1500, "and untimed tactics is untouched")
    }

    /// Games against the engine are rated, and against the strength that was
    /// actually set.
    @Test("The engine has a pool of its own")
    func engineIsRatedApart() {
        var progress = TrainingProgress()
        progress.record(game: GameRecord(
            playedAt: Date(), result: "win", accuracy: 90, blunders: 0, opponentElo: 2100
        ))

        #expect(progress.rating(.engine) > 1200)
        #expect(progress.rating(.online(minutes: 5)) == 1200)
        #expect(progress.gamesPlayed(.engine) == 1)
    }

    /// The identifier is what goes on disk, so it has to survive the trip.
    @Test("Every pool's identifier reads back as itself", arguments: [
        RatedPool.training(.tactics), .training(.endgame),
        .rush(minutes: 3), .online(minutes: 15), .engine,
    ])
    func identifiersRoundTrip(pool: RatedPool) {
        #expect(RatedPool(id: pool.id) == pool)
    }
}

@Suite("Watching")
struct WatchMarkTests {
    /// Rewinding to look at a move again is not un-watching the game.
    @Test("A mark only ever goes forward")
    func onlyForward() {
        var progress = TrainingProgress()
        progress.mark(watched: "morphy", ply: 30, of: 40)
        progress.mark(watched: "morphy", ply: 12, of: 40)

        #expect(progress.watchMark(for: "morphy")?.ply == 30)
    }

    @Test("A game watched to the last move is finished")
    func finishing() {
        var progress = TrainingProgress()
        progress.mark(watched: "rotlewi", ply: 25, of: 50)
        #expect(progress.watchMark(for: "rotlewi")?.isFinished == false)
        #expect(progress.watchMark(for: "rotlewi")?.fraction == 0.5)

        progress.mark(watched: "rotlewi", ply: 50, of: 50)
        #expect(progress.watchMark(for: "rotlewi")?.isFinished == true)
    }

    /// The list is nine hundred games; the memory of them is not unbounded.
    @Test("The oldest marks are the ones dropped")
    func forgetsTheOldestFirst() {
        var progress = TrainingProgress()
        let start = Date(timeIntervalSince1970: 0)
        for index in 0..<420 {
            progress.mark(watched: "game-\(index)", ply: 1, of: 10,
                          at: start.addingTimeInterval(Double(index)))
        }

        #expect(progress.watched.count == 400)
        #expect(progress.watchMark(for: "game-0") == nil, "the first watched should have gone")
        #expect(progress.watchMark(for: "game-419") != nil, "the last should not have")
    }

    @Test("Saving a game is a switch, not a one-way door")
    func favourites() {
        var progress = TrainingProgress()
        #expect(progress.isFavourite("steinitz") == false)
        progress.toggleFavourite("steinitz")
        #expect(progress.isFavourite("steinitz"))
        progress.toggleFavourite("steinitz")
        #expect(progress.isFavourite("steinitz") == false)
    }
}

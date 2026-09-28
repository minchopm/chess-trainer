import ChessCore
import Foundation
import Testing
@testable import ChessTraining

/// Hands every packet straight to the other session, so a whole game can be
/// played in a test without Game Center, two devices or two Apple IDs.
@MainActor
final class LoopbackTransport: MatchTransport {
    weak var peer: MatchSession?
    var dropped = false

    func send(_ data: Data) {
        guard !dropped else { return }
        peer?.receive(data)
    }
}

/// Holds the transports as well as the sessions. A session keeps only a weak
/// reference to its transport — in the app the Game Center service owns it, and
/// a strong link back would be a cycle — so a test that let them go out of
/// scope would be testing two sessions shouting into a void.
@MainActor
private final class Pair {
    let host: MatchSession
    let guest: MatchSession
    let hostTransport = LoopbackTransport()
    let guestTransport = LoopbackTransport()

    init(timeControl: TimeControl = .five, openPool: Bool = true) {
        host = MatchSession(
            transport: hostTransport,
            me: .init(playerID: "A", name: "Ann", rating: 1200, games: 0),
            isHost: true, timeControl: timeControl, openPool: openPool
        )
        guest = MatchSession(
            transport: guestTransport,
            me: .init(playerID: "B", name: "Bo", rating: 1200, games: 0),
            isHost: false, timeControl: timeControl, openPool: openPool
        )
        hostTransport.peer = guest
        guestTransport.peer = host
    }

    /// Both devices announce themselves; only the host deals the colours.
    func begin(hostPlaysWhite: Bool = true) {
        guest.begin()
        host.begin(whiteIsHost: hostPlaysWhite)
    }
}

@MainActor
private func makePair(timeControl: TimeControl = .five, openPool: Bool = true) -> Pair {
    Pair(timeControl: timeControl, openPool: openPool)
}

@Suite("Online match")
@MainActor
struct MatchTests {
    /// Neither device knows which of them will be ready first.
    ///
    /// Game Center hands both ends a match at more or less the same moment, but
    /// "more or less" is the whole problem: whichever session is built second
    /// misses anything the first one said. The deal therefore waits for the
    /// guest's hello rather than going out with the host's, and it has to work
    /// whichever order the two arrive in.
    @Test("The host waits for the guest before dealing")
    func hostWaitsForTheGuest() {
        let pair = makePair()

        pair.host.begin(whiteIsHost: true)
        #expect(pair.host.phase == .waiting, "nobody has answered yet")
        #expect(pair.guest.phase == .waiting)

        pair.guest.begin()
        #expect(pair.host.phase == .playing)
        #expect(pair.guest.phase == .playing)
        #expect(pair.host.myColor == .white)
        #expect(pair.guest.myColor == .black)
    }

    /// And a hello spoken into a void is said again.
    ///
    /// This is the case that hung: the guest's first hello goes out before the
    /// host has a session to hand it to, so it is dropped — not queued, not
    /// resent by anything underneath. Without the repeat both ends wait for the
    /// other to speak first, which is a game that never starts and never fails.
    @Test("A hello lost before the other side is listening is said again")
    func lostHelloIsSaidAgain() {
        let pair = makePair()

        pair.guestTransport.dropped = true
        pair.guest.begin()
        pair.host.begin(whiteIsHost: true)
        #expect(pair.host.phase == .waiting, "the host never heard the guest")
        #expect(pair.guest.phase == .waiting)

        pair.guestTransport.dropped = false
        pair.guest.tick(now: Date())
        #expect(pair.host.phase == .playing)
        #expect(pair.guest.phase == .playing)
        #expect(pair.guest.opponent?.name == "Ann", "and the host says who it is")
    }

    @Test("The host deals the colours and both sides agree")
    func colours() {
        let pair = makePair()
        pair.begin()

        #expect(pair.host.myColor == .white)
        #expect(pair.guest.myColor == .black)
        #expect(pair.host.isMyTurn)
        #expect(!pair.guest.isMyTurn)
        #expect(pair.guest.opponent?.name == "Ann")
        #expect(pair.host.opponent?.name == "Bo")
    }

    @Test("A move made on one board appears on the other")
    func movesCross() {
        let pair = makePair()
        pair.begin()

        #expect(pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))
        #expect(pair.guest.position.fen == pair.host.position.fen)
        #expect(pair.guest.moves == ["e4"])
        #expect(pair.guest.isMyTurn)
        #expect(!pair.host.isMyTurn)
    }

    @Test("A move out of turn is refused rather than sent")
    func refusesOutOfTurn() {
        let pair = makePair()
        pair.begin()

        #expect(!pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil))
        #expect(pair.guest.moves.isEmpty)
        #expect(pair.host.moves.isEmpty)
    }

    @Test("Checkmate ends both sides, one as a win and one as a loss")
    func checkmate() {
        let pair = makePair()
        pair.begin()

        // Fool's mate: 1.f3 e5 2.g4 Qh4#
        pair.host.play(from: Square("f2")!, to: Square("f3")!, promotion: nil)
        pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil)
        pair.host.play(from: Square("g2")!, to: Square("g4")!, promotion: nil)
        pair.guest.play(from: Square("d8")!, to: Square("h4")!, promotion: nil)

        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .checkmate)))
        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .checkmate)))
    }

    /// A flag has to end the game even when the device it belongs to is asleep.
    ///
    /// Only the owner used to claim it, which reads well and assumes the owner
    /// is awake to say so. A phone whose screen has locked is not, and the game
    /// then ran on past zero with the clock showing nothing left — decided by
    /// whatever happened after, on a board that should have been over.
    @Test("A flag the other device never reports is claimed here")
    func opponentFlagIsClaimed() {
        let pair = makePair(timeControl: .three)
        pair.begin()
        // One move, so that it is the guest thinking and the guest's clock
        // that runs out.
        #expect(pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))

        let out = Date().addingTimeInterval(TimeControl.three.seconds + 1)
        pair.host.tick(now: out)
        #expect(pair.host.phase == .playing, "not on sight: their move may be on the wire")

        pair.host.tick(now: out.addingTimeInterval(4))
        #expect(pair.host.phase == .finished(MatchResult(outcome: .win, reason: .timeout)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .loss, reason: .timeout)),
                "and the other device is told, rather than left on a dead board")
    }

    /// Each device is a network hop kinder to itself than the other is, so a
    /// move carries both readings and each is taken downwards. Without it the
    /// two screens disagree, and one player can be out of time on the other's
    /// while still thinking on their own.
    @Test("A move's reading of your own clock is taken, downwards only")
    func adoptsTheirReadingOfYourClock() throws {
        let pair = makePair()
        pair.begin()
        #expect(pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))

        func answer(yours: TimeInterval) throws -> Data {
            try JSONEncoder().encode(MatchPacket.move(
                .init(uci: "e7e5", ply: 2, remaining: 280, yours: yours)
            ))
        }

        // Their reading of the host's clock is lower than the host's own, which
        // is what a slow link looks like from the other end.
        pair.host.receive(try answer(yours: 120))
        let now = Date()
        #expect(pair.host.clock.remaining(.white, at: now) <= 120.5)

        // And a reading that is higher is not taken: a modified build does not
        // get to hand itself time.
        let before = pair.host.clock.remaining(.white, at: now)
        pair.host.receive(try JSONEncoder().encode(MatchPacket.move(
            .init(uci: "g8f6", ply: 4, remaining: 270, yours: 999)
        )))
        #expect(pair.host.clock.remaining(.white, at: now) <= before)
    }

    @Test("Resigning loses for the sender and wins for the receiver")
    func resignation() {
        let pair = makePair()
        pair.begin()
        pair.host.resign()

        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .resignation)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .resignation)))
    }

    @Test("A draw is agreed only when the offer is accepted")
    func drawOffer() {
        let pair = makePair()
        pair.begin()

        pair.host.offerDraw()
        #expect(pair.guest.drawOffered)

        pair.guest.respondToDraw(accept: false)
        #expect(!pair.guest.drawOffered)
        #expect(pair.host.phase == .playing)

        pair.host.offerDraw()
        pair.guest.respondToDraw(accept: true)
        #expect(pair.host.phase == .finished(MatchResult(outcome: .draw, reason: .agreement)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .draw, reason: .agreement)))
    }

    @Test("Your own flag ends the game at once; the opponent's waits a moment")
    func flagFall() {
        let pair = makePair(timeControl: .three)
        pair.begin()
        let later = Date().addingTimeInterval(TimeControl.three.seconds + 1)

        // The guest can see the host is out of time, but not yet: their move
        // may be on the wire, and this device's reading of their clock is the
        // lower of the two. See `opponentFlagIsClaimed` for the other end of
        // this — the grace runs out and the claim is made.
        pair.guest.tick(now: later)
        #expect(pair.guest.phase == .playing)

        // The owner of the clock has no such doubt.
        pair.host.tick(now: later)
        #expect(pair.host.phase == .finished(MatchResult(outcome: .loss, reason: .timeout)))
        #expect(pair.guest.phase == .finished(MatchResult(outcome: .win, reason: .timeout)))
    }

    @Test("A packet from a peer that lies is dropped, not played")
    func rejectsIllegalRemoteMoves() throws {
        let pair = makePair()
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)

        // A rook teleporting off its starting square, with the right ply.
        let lie = MatchPacket.move(.init(uci: "a8a5", ply: 2, remaining: 100))
        pair.host.receive(try JSONEncoder().encode(lie))

        #expect(pair.host.moves == ["e4"])
        #expect(pair.host.position[Square("a8")!] == Piece(.black, .rook))
    }

    @Test("A move replayed after a retry is not played twice")
    func ignoresDuplicates() throws {
        let pair = makePair()
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)
        pair.guest.play(from: Square("e7")!, to: Square("e5")!, promotion: nil)

        let repeated = MatchPacket.move(.init(uci: "e7e5", ply: 2, remaining: 100))
        pair.host.receive(try JSONEncoder().encode(repeated))

        #expect(pair.host.moves == ["e4", "e5"])
    }

    @Test("The opponent's clock is trusted downwards only")
    func clockCannotBeInflated() throws {
        let pair = makePair(timeControl: .three)
        pair.begin()
        pair.host.play(from: Square("e2")!, to: Square("e4")!, promotion: nil)

        let generous = MatchPacket.move(.init(uci: "e7e5", ply: 2, remaining: 9_999))
        pair.host.receive(try JSONEncoder().encode(generous))

        #expect(pair.host.clock.remaining(.black) <= TimeControl.three.seconds)
    }

    @Test("The rating moves by Glicko, once")
    func rating() throws {
        let pair = makePair()
        pair.begin()
        pair.host.resign()

        // Two new players: wide deviations, so the first result moves a lot.
        let settled = try #require(pair.guest.settle(rating: 1200, deviation: 350))
        #expect(settled.ratingDelta == 162)
        #expect(abs((settled.deviation ?? 0) - 290.2) < 0.1, "and the rating is surer for it")
        #expect(pair.guest.settle(rating: 1362, deviation: 290) == nil)
    }

    @Test("Another game, when both want one, swaps the colours and starts again")
    func rematchSwapsColours() {
        let pair = makePair()
        pair.begin(hostPlaysWhite: true)
        pair.host.resign()
        #expect(pair.guest.settle(rating: 1200, deviation: 350)?.ratingDelta == 162)

        // The winner asks, with the rating the game left.
        pair.guest.offerRematch(as: .init(playerID: "B", name: "Bo", rating: 1362, games: 1, deviation: 290))
        #expect(pair.guest.rematchOfferSent)
        #expect(pair.host.rematchOffered)

        pair.host.respondToRematch(accept: true)
        #expect(pair.host.phase == .playing)
        #expect(pair.guest.phase == .playing)
        #expect(pair.host.myColor == .black)
        #expect(pair.guest.myColor == .white)
        #expect(pair.host.gameNumber == 2 && pair.guest.gameNumber == 2)
        #expect(pair.host.opponent?.rating == 1362, "the new game is scored against the new rating")
        #expect(pair.host.moves.isEmpty && !pair.guest.rematchOfferSent && !pair.host.rematchOffered)

        // And it is a game: White moves first, on both boards.
        #expect(pair.guest.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))
        #expect(pair.host.moves == ["e4"])
    }

    @Test("Asking for another game at the same moment is a yes from both")
    func rematchCrossedOffers() {
        let pair = makePair()
        pair.begin(hostPlaysWhite: false)
        pair.host.resign()
        // Each asks before hearing the other: the packets cross.
        pair.hostTransport.dropped = true
        pair.host.offerRematch()
        pair.hostTransport.dropped = false
        pair.guest.offerRematch()             // reaches the host, who had asked
        #expect(pair.host.phase == .playing)
        #expect(pair.guest.phase == .playing)
        #expect(pair.host.myColor == .white && pair.guest.myColor == .black)
        #expect(pair.host.gameNumber == 2 && pair.guest.gameNumber == 2)
    }

    @Test("A declined rematch, and an opponent who has left, end the asking")
    func rematchDeclinedAndLeft() {
        let pair = makePair()
        pair.begin()
        pair.guest.resign()
        pair.host.offerRematch()
        pair.guest.respondToRematch(accept: false)
        #expect(pair.host.rematchDeclined)
        #expect(!pair.host.rematchOfferSent)
        if case .finished = pair.host.phase {} else { Issue.record("no new game was started") }

        pair.guest.leave()
        #expect(pair.host.opponentLeft)
        pair.host.offerRematch()
        #expect(!pair.host.rematchOfferSent, "nobody is there to ask")
    }

    @Test("Saying goodbye in the middle of a game loses it")
    func goodbyeMidGame() {
        let pair = makePair()
        pair.begin()
        pair.guest.leave()
        #expect(pair.host.phase == .finished(MatchResult(outcome: .win, reason: .disconnected)))
    }

    // MARK: - What counts for the rating

    @Test("A game from the open search counts; an invitation's and a rematch's do not")
    func whichGamesAreRated() {
        let open = makePair()
        open.begin()
        #expect(open.host.unratedByMatch == nil && open.guest.unratedByMatch == nil)
        open.host.resign()
        open.guest.offerRematch()
        open.host.respondToRematch(accept: true)
        #expect(open.host.gameNumber == 2)
        #expect(open.host.unratedByMatch == .rematch && open.guest.unratedByMatch == .rematch)

        let invited = makePair(openPool: false)
        invited.begin()
        #expect(invited.host.unratedByMatch == .invitation && invited.guest.unratedByMatch == .invitation)
    }

    @Test("One rated game a day against the same opponent")
    func oneRatedGameADayPerOpponent() throws {
        var progress = TrainingProgress()
        let noon = Date(timeIntervalSince1970: 1_790_000_000)
        #expect(progress.canRate(against: "B", at: noon))
        progress.noteRated(against: "B", at: noon)
        #expect(!progress.canRate(against: "B", at: noon.addingTimeInterval(3600)))
        #expect(progress.canRate(against: "C", at: noon.addingTimeInterval(3600)), "somebody else still counts")
        #expect(progress.canRate(against: "B", at: noon.addingTimeInterval(24 * 3600)))

        // Kept on disk, and a day later forgotten rather than kept for ever.
        let saved = try JSONDecoder().decode(TrainingProgress.self, from: JSONEncoder().encode(progress))
        #expect(!saved.canRate(against: "B", at: noon.addingTimeInterval(60)))
        progress.noteRated(against: "C", at: noon.addingTimeInterval(25 * 3600))
        #expect(progress.ratedOpponents.keys.sorted() == ["C"])
    }

    // MARK: - Glicko

    @Test("Beating somebody far below earns nothing, and drawing with them costs")
    func glickoFollowsTheGap() {
        func after(_ rating: Int, against opponent: Int, score: Double) -> Int {
            Glicko.updated(rating: rating, deviation: 50, against: opponent, opponentDeviation: 50, score: score).rating
        }
        #expect(after(2000, against: 1200, score: 1) == 2000, "eight hundred points below: nothing")
        #expect(after(1800, against: 1500, score: 1) == 1802, "three hundred below: a little")
        #expect(after(1500, against: 1500, score: 1) == 1507, "an equal: the usual")
        #expect(after(1500, against: 2300, score: 1) == 1514, "far above: the most")
        #expect(after(1800, against: 1500, score: 0.5) == 1795, "a draw with somebody below loses points")
        #expect(after(1500, against: 1500, score: 0.5) == 1500)
        #expect(after(1500, against: 1800, score: 0.5) == 1505, "and gains them against somebody above")
    }

    @Test("No ceiling, a floor at a hundred")
    func glickoHasNoCeiling() {
        #expect(Glicko.updated(rating: 3000, deviation: 50, against: 3000, opponentDeviation: 50, score: 1).rating == 3007)
        #expect(Glicko.updated(rating: 4100, deviation: 50, against: 4100, opponentDeviation: 50, score: 1).rating > 4100)
        #expect(Glicko.updated(rating: 105, deviation: 200, against: 110, opponentDeviation: 50, score: 0).rating == Glicko.floor)
        #expect(Elo.updated(rating: 3000, games: 200, against: 3000, score: 1) == 3008, "the training ratings have no ceiling either")
    }

    @Test("A rating grows surer with games and less sure without them")
    func glickoDeviation() {
        #expect(Glicko.deviation(games: 0) == Glicko.newDeviation)
        #expect(Glicko.deviation(games: 500) == Glicko.settledDeviation)
        #expect(Glicko.deviation(50, idle: 0) == 50)
        #expect(Glicko.deviation(50, idle: 30 * 86_400) > 100, "a month away")
        #expect(Glicko.deviation(50, idle: 400 * 86_400) == Glicko.newDeviation, "a year away, and never wider than new")

        var progress = TrainingProgress()
        let pool = RatedPool.online(minutes: 5)
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        #expect(progress.deviation(pool, at: day) == Glicko.newDeviation)
        progress.record(online: MatchResult(outcome: .win, reason: .checkmate, ratingDelta: 162), at: .five, now: day)
        #expect(progress.rating(pool) == Glicko.starting + 162)
        // A result that came without a deviation keeps the one there was.
        #expect(progress.deviation(pool, at: day) == Glicko.newDeviation)
        var surer = MatchResult(outcome: .win, reason: .checkmate, ratingDelta: 10)
        surer.deviation = 200
        progress.record(online: surer, at: .five, now: day)
        #expect(progress.deviation(pool, at: day) == 200)
        #expect(progress.deviation(pool, at: day.addingTimeInterval(60 * 86_400)) > 200)
    }
}

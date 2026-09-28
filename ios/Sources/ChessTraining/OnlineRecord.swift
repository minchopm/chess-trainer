import Foundation

/// A player's online rating on one clock, as Game Center keeps it.
///
/// Game Center is where online ratings live: each clock's leaderboard holds
/// every player's most recent one, written only by this app, signed as this
/// app. A leaderboard entry is a score and a 64-bit context, and Glicko needs
/// more than a number — so the score is the rating, which is what the list
/// sorts by and shows, and the context carries the rest: how sure the rating
/// is, how many rated games it has, and the day of the last one, which is how
/// far its deviation has widened since.
///
/// Read from Game Center, never from this device's own copy: that is a file
/// in the app's container, and on a Mac anybody can open it in a text editor.
public struct OnlineRecord: Equatable, Sendable {
    public var rating: Int
    /// As of `lastPlayed`; see `deviation(at:)` for now.
    public var deviation: Double
    public var games: Int
    public var lastPlayed: Date?

    public init(rating: Int, deviation: Double, games: Int, lastPlayed: Date?) {
        self.rating = rating
        self.deviation = deviation
        self.games = games
        self.lastPlayed = lastPlayed
    }

    /// Somebody Game Center has no rating for on this clock.
    public static let new = OnlineRecord(rating: Glicko.starting, deviation: Glicko.newDeviation, games: 0, lastPlayed: nil)

    /// How sure the rating is today: widened by the time since the last game.
    public func deviation(at now: Date = Date()) -> Double {
        guard let lastPlayed else { return deviation }
        return Glicko.deviation(deviation, idle: now.timeIntervalSince(lastPlayed))
    }

    // MARK: - The context

    private static let deviationBits = 10
    private static let gamesBits = 22
    private static let day: TimeInterval = 86_400

    /// The deviation, the games and the day of the last game, in one integer:
    /// ten bits, twenty-two and thirty-two, from the bottom.
    public var context: Int {
        let d = min(max(Int(deviation.rounded()), 0), (1 << Self.deviationBits) - 1)
        let g = min(max(games, 0), (1 << Self.gamesBits) - 1)
        let day = lastPlayed.map { max(Int($0.timeIntervalSince1970 / Self.day), 0) } ?? 0
        return (day << (Self.deviationBits + Self.gamesBits)) | (g << Self.deviationBits) | d
    }

    /// An entry read back. One with no context — written before the context
    /// carried anything — is a rating whose certainty is not known, which is
    /// what a new player's deviation says.
    public init(score: Int, context: Int) {
        let d = context & ((1 << Self.deviationBits) - 1)
        let g = (context >> Self.deviationBits) & ((1 << Self.gamesBits) - 1)
        let day = context >> (Self.deviationBits + Self.gamesBits)
        self.init(
            rating: max(score, Glicko.floor),
            deviation: d == 0 ? Glicko.newDeviation : Double(d),
            games: g,
            lastPlayed: day == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(day) * Self.day)
        )
    }

    /// The record after one game against `opponent`, scored by Glicko.
    public func after(_ score: Double, against opponent: OnlineRecord, at now: Date = Date()) -> OnlineRecord {
        let next = Glicko.updated(
            rating: rating, deviation: deviation(at: now),
            against: opponent.rating, opponentDeviation: opponent.deviation(at: now),
            score: score
        )
        return OnlineRecord(rating: next.rating, deviation: next.deviation, games: games + 1, lastPlayed: now)
    }
}

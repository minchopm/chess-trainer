import Foundation

/// The clocks an online game can be played at.
///
/// Minutes only, no increment. An increment changes how a game is played more
/// than the base time does, and offering both would double the matchmaking
/// pools — at which point the wait for an opponent becomes the feature people
/// notice.
public enum TimeControl: Int, CaseIterable, Identifiable, Codable, Sendable {
    case three = 3, five = 5, ten = 10, fifteen = 15, thirty = 30

    public var id: Int { rawValue }
    public var minutes: Int { rawValue }
    public var seconds: TimeInterval { TimeInterval(rawValue * 60) }
    public var label: String { L.t("clock.minutes", "%lld min", rawValue) }

    /// What the clock is called at the board. Worth showing: a player who knows
    /// they are bad at blitz should be able to see it before they queue.
    public var name: String {
        switch self {
        case .three, .five: L.t("clock.blitz", "Blitz")
        case .ten, .fifteen: L.t("clock.rapid", "Rapid")
        case .thirty: L.t("clock.classical", "Classical")
        }
    }

    /// Matchmaking pool. Players only ever meet others who chose the same
    /// clock — being handed three minutes when you asked for thirty is not a
    /// game of chess, it is a different sport.
    public var playerGroup: Int { 4000 + rawValue }

    public static func fromPlayerGroup(_ group: Int) -> TimeControl? {
        TimeControl(rawValue: group - 4000)
    }
}

/// Two clocks and a side to move.
///
/// Time is kept as a remaining amount plus the instant the side to move started
/// thinking, rather than as a value counted down by a timer. A timer that fires
/// sixty times a second is sixty chances to drift; this way the display can
/// tick as often or as rarely as it likes and still be right, and a view that
/// was not drawn for a second does not owe the player that second back.
public struct ChessClock: Equatable, Sendable {
    public let timeControl: TimeControl
    public private(set) var remaining: [PieceColorKey: TimeInterval]
    public private(set) var turn: PieceColorKey
    public private(set) var startedAt: Date?

    /// Colours as a dictionary key. ChessCore's PieceColor would do, but the
    /// clock is deliberately free of the rules: it counts time for two sides
    /// and has no opinion about what they are doing.
    public enum PieceColorKey: String, Codable, Sendable, CaseIterable {
        case white, black
        public var other: PieceColorKey { self == .white ? .black : .white }
    }

    public init(timeControl: TimeControl, turn: PieceColorKey = .white) {
        self.timeControl = timeControl
        self.turn = turn
        self.remaining = [.white: timeControl.seconds, .black: timeControl.seconds]
        self.startedAt = nil
    }

    public var isRunning: Bool { startedAt != nil }

    public func remaining(_ side: PieceColorKey, at now: Date = Date()) -> TimeInterval {
        let stored = remaining[side] ?? 0
        guard side == turn, let startedAt else { return max(0, stored) }
        return max(0, stored - now.timeIntervalSince(startedAt))
    }

    public func hasFlagged(_ side: PieceColorKey, at now: Date = Date()) -> Bool {
        remaining(side, at: now) <= 0
    }

    public mutating func start(at now: Date = Date()) {
        guard startedAt == nil else { return }
        startedAt = now
    }

    /// End the side to move's turn: bank what is left and hand the clock over.
    public mutating func press(at now: Date = Date()) {
        remaining[turn] = remaining(turn, at: now)
        turn = turn.other
        startedAt = now
    }

    public mutating func stop(at now: Date = Date()) {
        remaining[turn] = remaining(turn, at: now)
        startedAt = nil
    }

    /// Take the opponent's own reading of their clock, as sent with their move.
    ///
    /// Trusted only downwards. Their device knows how long they really thought,
    /// including the part of it spent on the network, and no peer-to-peer game
    /// can do better than ask them — but accepting an increase would let a
    /// modified build hand itself unlimited time.
    public mutating func adopt(_ value: TimeInterval, for side: PieceColorKey) {
        let current = remaining[side] ?? 0
        remaining[side] = max(0, min(current, value))
    }

    public static func text(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.up))
        if whole >= 60 { return String(format: "%d:%02d", whole / 60, whole % 60) }
        // Under a minute the tenths are the whole story.
        return String(format: "%.1f", max(0, seconds))
    }
}

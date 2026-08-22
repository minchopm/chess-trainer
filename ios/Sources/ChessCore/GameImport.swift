import Foundation

/// A game or a position, read out of whatever somebody pasted in.
///
/// People arrive with what they have: a FEN copied from an engine, a PGN saved
/// from a site, the bare moves typed out of a book, or a list of UCI moves from
/// a log. All four are the same question — *what position is this, and how did
/// it get there* — so all four are read here rather than in four places.
public struct GameImport: Equatable, Sendable {
    /// Where the line starts. The standard array unless a FEN said otherwise.
    public let start: Position
    /// The moves that were readable, in order.
    public let moves: [Move]
    /// The position after the last readable move.
    public let final: Position
    /// Set when the text ran out mid-line: the token that could not be played,
    /// and how far it got. A paste with a typo in move thirty should give back
    /// twenty-nine moves and say so, not nothing and no reason.
    public let stoppedAt: (token: String, afterMoves: Int)?

    public static func == (lhs: GameImport, rhs: GameImport) -> Bool {
        lhs.start.fen == rhs.start.fen && lhs.moves == rhs.moves
            && lhs.final.fen == rhs.final.fen
            && lhs.stoppedAt?.token == rhs.stoppedAt?.token
            && lhs.stoppedAt?.afterMoves == rhs.stoppedAt?.afterMoves
    }

    public var isEmpty: Bool { moves.isEmpty }
}

public extension GameImport {
    /// Reads a paste. Returns nil only when there is no position to be had at
    /// all — not when some of the moves failed, which is reported instead.
    static func read(_ text: String) -> GameImport? {
        let headers = pgnHeaders(in: text)
        let start = headers["FEN"].flatMap(Position.init(fen:))
            ?? bareFEN(in: text)
            ?? Position()

        var position = start
        var moves: [Move] = []
        var stopped: (String, Int)?

        for token in tokens(in: text) {
            guard let move = move(token, in: position) else {
                stopped = (token, moves.count)
                break
            }
            guard let made = position.make(move) else {
                stopped = (token, moves.count)
                break
            }
            moves.append(made)
        }

        // A paste that yields neither a position of its own nor a single move
        // is not an import, it is a typo.
        if moves.isEmpty, start.fen == Position().fen, bareFEN(in: text) == nil,
           headers["FEN"] == nil {
            return nil
        }
        return GameImport(start: start, moves: moves, final: position, stoppedAt: stopped)
    }

    /// One move, in either of the two ways they are written down.
    private static func move(_ token: String, in position: Position) -> Move? {
        if let san = position.move(san: token) { return san }
        // UCI: e2e4, or e7e8q for a promotion.
        guard token.count == 4 || token.count == 5, let uci = Move(uci: token) else { return nil }
        return position.legalMoves().first { $0.matchesNotation(of: uci) }
    }

    /// `[Event "..."]` and friends.
    private static func pgnHeaders(in text: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("["), trimmed.hasSuffix("]") else { continue }
            let body = trimmed.dropFirst().dropLast()
            guard let space = body.firstIndex(of: " ") else { continue }
            let name = String(body[body.startIndex..<space])
            let value = body[body.index(after: space)...]
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            headers[name] = value
        }
        return headers
    }

    /// A FEN pasted on its own, with no PGN around it.
    private static func bareFEN(in text: String) -> Position? {
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Six fields and a slash in the first is what makes a FEN a FEN.
            let fields = trimmed.split(separator: " ")
            guard fields.count >= 4, fields[0].contains("/") else { continue }
            if let position = Position(fen: trimmed) { return position }
        }
        return nil
    }

    /// The move tokens, with everything a PGN carries around them removed.
    ///
    /// Headers, comments in braces, variations in brackets, the numbers, the
    /// glyphs and the result. What is left is the mainline, which is the line
    /// somebody meant to give us — a variation is somebody else's idea about a
    /// move that was not played.
    private static func tokens(in text: String) -> [String] {
        var stripped = ""
        var braces = 0
        var brackets = 0
        var inHeader = false

        for character in text {
            switch character {
            case "{": braces += 1
            case "}": braces = max(0, braces - 1)
            case "(": brackets += 1
            case ")": brackets = max(0, brackets - 1)
            case "[": inHeader = true
            case "]": inHeader = false
            case ";":
                // A semicolon comments out the rest of its line.
                braces += 1
            case "\n":
                if braces > 0 { braces = 0 }
                stripped.append(" ")
            default:
                if braces == 0, brackets == 0, !inHeader { stripped.append(character) }
            }
        }

        return stripped.split(whereSeparator: \.isWhitespace).compactMap { raw in
            var token = String(raw)
            // "12." and "12..." are numbering, and "12.e4" is numbering with a
            // move stuck to it.
            while let first = token.first, first.isNumber || first == "." {
                if let dot = token.firstIndex(of: "."), token.prefix(upTo: dot).allSatisfy(\.isNumber) {
                    token = String(token[token.index(after: dot)...])
                    while token.first == "." { token.removeFirst() }
                } else if token.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" || $0 == "/" }) {
                    return nil          // a move number, or a result like 1-0
                } else {
                    break
                }
            }
            guard !token.isEmpty, token != "*", !token.hasPrefix("$") else { return nil }
            if ["1-0", "0-1", "1/2-1/2", "½-½"].contains(token) { return nil }
            return token
        }
    }
}

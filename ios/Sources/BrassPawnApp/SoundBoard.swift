import AVFoundation
import ChessCore
import ChessTraining
import Foundation

/// The noise a move makes.
///
/// Synthesised rather than recorded, and deliberately plain: a short burst of
/// noise for the contact and two decaying tones for the board under it. Sound
/// is the one part of a chess app that tells you a move happened without you
/// having to look, which matters most exactly when you are not looking — while
/// the opponent replies.
@MainActor
public final class SoundBoard {
    public enum Cue: String, CaseIterable {
        case move, capture, check, castle, promote, gameEnd
    }

    public static let shared = SoundBoard()

    /// Kept here rather than passed to every call site: a view model deep in a
    /// puzzle should not have to know where the preference lives.
    public var isEnabled = true
    /// 0...1, applied on top of each cue's own level so a capture stays louder
    /// than a move however far the slider is turned down.
    public var volume: Double = 0.7 {
        didSet { applyVolume() }
    }

    private var players: [Cue: AVAudioPlayer] = [:]
    private var configured = false

    private init() {}

    /// Plays through the ambient category, so the silent switch silences it and
    /// nothing interrupts whatever the player is listening to. A chess app that
    /// stops somebody's music to click at them has overstepped.
    private func configure() {
        guard !configured else { return }
        configured = true
        #if canImport(AVFAudio) && !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        for cue in Cue.allCases {
            guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else { continue }
            player.prepareToPlay()
            players[cue] = player
        }
    }

    private func applyVolume() {
        for (cue, player) in players {
            player.volume = Float(volume) * (cue == .move ? 0.7 : 0.85)
        }
    }

    public func play(_ cue: Cue) {
        guard isEnabled, volume > 0 else { return }
        configure()
        applyVolume()
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }

    /// Picks the cue a move deserves from the position it produced, so callers
    /// say "this move happened" rather than choosing sounds themselves.
    public func play(move: Move, captured: Bool, resulting: Position) {
        guard isEnabled else { return }
        if resulting.isCheckmate || resulting.isDraw {
            play(.gameEnd)
        } else if resulting.isCheck {
            play(.check)
        } else if move.kind == .kingsideCastle || move.kind == .queensideCastle {
            play(.castle)
        } else if move.promotion != nil {
            play(.promote)
        } else {
            play(captured ? .capture : .move)
        }
    }
}

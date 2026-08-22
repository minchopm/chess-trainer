import ChessEngine
import ChessTraining
import Testing
@testable import BrassPawnApp

/// `EngineChoice.limitsStrength` is a copy of `EngineCapabilities.limitsStrength`
/// kept in ChessTraining, which cannot see the engines — it is what lets the
/// settings describe a choice before an engine has been built.
///
/// A copy is a thing that goes stale. This is what notices: it builds each engine
/// and asks it, rather than trusting the enum. If Reckless ever gains a strength
/// limiter, or the two are wired up the wrong way round, this fails rather than
/// the app quietly offering ratings nothing can hit.
@Suite(.serialized)
struct EngineCapabilityTests {
    @Test("Every choice's claim about strength matches the engine it names")
    func claimsMatchTheEngines() async throws {
        for choice in EngineChoice.allCases {
            let engine: any Engine = switch choice {
            case .stockfish: StockfishEngine()
            case .reckless: RecklessEngine()
            }
            #expect(engine.capabilities.limitsStrength == choice.limitsStrength,
                    "\(choice.name) claims limitsStrength = \(choice.limitsStrength)")
        }
    }

    /// The name in Settings should be the engine's own, not the enum's label.
    @Test("Each engine's reported name begins with the name it is chosen by")
    func namesAgree() async throws {
        #expect(StockfishEngine().capabilities.name.hasPrefix(EngineChoice.stockfish.name))
        #expect(RecklessEngine().capabilities.name.hasPrefix(EngineChoice.reckless.name))
    }
}

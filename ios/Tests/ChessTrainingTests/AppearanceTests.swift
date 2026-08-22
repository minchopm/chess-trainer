import Foundation
import Testing
@testable import ChessTraining

@Suite("Application typeface")
struct AppearanceTests {
    @Test("System is the default typeface")
    func defaultTypeface() {
        #expect(Appearance().typeface == .system)
    }

    @Test("The selected typeface persists")
    func selectedTypefacePersists() throws {
        var appearance = Appearance()
        appearance.typeface = .jetBrainsMono

        let data = try JSONEncoder().encode(appearance)
        let decoded = try JSONDecoder().decode(Appearance.self, from: data)

        #expect(decoded.typeface == .jetBrainsMono)
    }

    @Test("Legacy appearance data defaults to the system typeface")
    func legacyAppearanceDefaultsToSystem() throws {
        let json = #"{"pieces":"ebony","board":"wood","soundsOn":true,"volume":0.7,"dimension":"flat","carving":"banded"}"#
        let decoded = try JSONDecoder().decode(Appearance.self, from: Data(json.utf8))

        #expect(decoded.typeface == .system)
    }
}

@Suite("Engine choice")
struct EngineChoiceTests {
    @Test("Stockfish is the default engine")
    func defaultEngine() {
        #expect(Appearance().engine == .stockfish)
    }

    @Test("The selected engine persists")
    func selectedEnginePersists() throws {
        var appearance = Appearance()
        appearance.engine = .reckless

        let data = try JSONEncoder().encode(appearance)
        let decoded = try JSONDecoder().decode(Appearance.self, from: data)

        #expect(decoded.engine == .reckless)
    }

    /// Somebody who already has the app has a saved file with no engine in it,
    /// and they have been playing Stockfish's ladder. Loading that as anything
    /// else would change their opponent on update without asking.
    @Test("A save from before the choice existed still loads, as Stockfish")
    func legacySaveDefaultsToStockfish() throws {
        let json = #"{"pieces":"ebony","board":"wood","soundsOn":true,"volume":0.7,"dimension":"flat","carving":"banded","showsCoordinates":true}"#
        let decoded = try JSONDecoder().decode(Appearance.self, from: Data(json.utf8))

        #expect(decoded.engine == .stockfish)
    }

    /// The one difference between the two that the player can see.
    @Test("Only Stockfish claims to limit its strength")
    func onlyStockfishLimitsStrength() {
        #expect(EngineChoice.stockfish.limitsStrength)
        #expect(!EngineChoice.reckless.limitsStrength)
    }
}

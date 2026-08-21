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

import Foundation
import Testing

/// What About says, in every language it says it in.
@Suite("About, in every language")
struct AboutCopy {
    /// Every language's value for one key, read fresh: a JSON dictionary is
    /// not `Sendable`, so nothing of it is kept between tests.
    static func values(_ key: String) -> [String: String] {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "App/Localizable.xcstrings")
        let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let entry = (json["strings"] as! [String: Any])[key] as! [String: Any]
        let locs = entry["localizations"] as! [String: [String: Any]]
        return locs.mapValues { (($0["stringUnit"] as! [String: Any])["value"] as! String) }
    }

    /// The licence is explained in two paragraphs, and the engines are named in
    /// the first. The second used to open by introducing Reckless all over
    /// again — in all thirty-two languages, because the first had been rewritten
    /// to name both engines and the second never was.
    @Test("each engine is introduced once")
    func enginesIntroducedOnce() {
        let first = Self.values("about.itIncludesStockfishWhichIs")
        let second = Self.values("about.itAlsoIncludesReckless")
        #expect(first.count == second.count)
        for (lang, text) in first {
            #expect(text.contains("Stockfish") && text.contains("Reckless"), "\(lang): \(text)")
        }
        for (lang, text) in second {
            #expect(!text.contains("Reckless"), "\(lang) introduces Reckless a second time: \(text)")
        }
    }

    /// The tagline is read on a Mac and an iPad as often as on a phone, and it
    /// promised that nothing leaves "the phone" — which online play, whose moves
    /// go through Game Center, never made true anyway.
    @Test("the tagline does not assume a phone")
    func taglineIsDeviceNeutral() {
        for (lang, text) in Self.values("about.intro3") where lang.hasPrefix("en") {
            #expect(!text.lowercased().contains("phone"), "\(lang): \(text)")
        }
    }

    /// The privacy copy can no longer say nothing is collected: while the app
    /// is on screen it says who is online. Every language has to say so, and
    /// that the ratings are Game Center's.
    @Test("the privacy copy says what online play sends, in every language")
    func privacyNamesPresence() {
        let intro = Self.values("about.intro3")
        let apart = Self.values("about.privacyApart")
        let online = Self.values("about.onlinePresence")
        #expect(intro.count == 32 && apart.count == 32 && online.count == 32)
        for (lang, text) in online {
            #expect(text.contains("Game Center"), "\(lang): \(text)")
        }
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "App/Localizable.xcstrings")
        let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        for key in ["about.gameCenterLists", "about.theAppCollectsNothingSends", "about.tacticsPositionalJudgementEndgameTechnique",
                    "about.onlineReferee", "about.intro2"] {
            #expect((json["strings"] as! [String: Any])[key] == nil, "\(key) is out of date")
        }
    }
}

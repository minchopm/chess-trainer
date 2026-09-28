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
        for (lang, text) in Self.values("about.intro2") where lang.hasPrefix("en") {
            #expect(!text.lowercased().contains("phone"), "\(lang): \(text)")
        }
    }

    /// Online ratings are the referee's, so the privacy copy can no longer say
    /// nothing is collected, or that Game Center has it all: every language
    /// has to say there is an exception, and what it is.
    @Test("the privacy copy owns up to the referee, in every language")
    func privacyNamesTheReferee() {
        let intro = Self.values("about.intro2")
        let apart = Self.values("about.privacyApart")
        let referee = Self.values("about.onlineReferee")
        #expect(intro.count == 32 && apart.count == 32 && referee.count == 32)
        for (lang, text) in referee {
            #expect(text.contains("Game Center"), "\(lang): \(text)")
        }
        for key in ["about.gameCenterLists", "about.theAppCollectsNothingSends", "about.tacticsPositionalJudgementEndgameTechnique"] {
            let url = URL(filePath: #filePath)
                .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appending(path: "App/Localizable.xcstrings")
            let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
            #expect((json["strings"] as! [String: Any])[key] == nil, "\(key) said nothing was collected")
        }
    }
}

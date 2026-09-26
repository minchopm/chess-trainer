import Foundation
import Testing
@testable import BrassPawnApp

/// Today's words, in every language, and the address the site opens it with.
@Suite("Today")
struct TodayCopy {
    /// A placeholder a translation lost is a name that never appears, or a
    /// crash in `String(format:)` — so every language has to keep every one.
    @Test("every translation keeps its placeholders")
    func placeholders() {
        let pattern = /%(\d\$)?(@|lld)/
        for key in ["today.beat", "today.drew", "today.round", "today.keyMove", "today.after", "today.stockfish"] {
            let values = AboutCopy.values(key)
            let english = values["en"]!.matches(of: pattern).map { String($0.output.0) }.sorted()
            #expect(values.count == 32, "\(key) is in \(values.count) languages")
            for (lang, text) in values {
                let found = text.matches(of: pattern).map { String($0.output.0) }.sorted()
                #expect(found == english, "\(key) in \(lang) has \(found), English has \(english)")
            }
        }
    }

    /// About says what the app downloads, and calls the screen it happens on
    /// by the name the menu gives it.
    @Test("About names the screen that downloads the feed")
    func aboutNamesToday() {
        let today = AboutCopy.values("today.title")
        let about = AboutCopy.values("about.theAppCollectsNothingSends")
        for (lang, text) in about {
            #expect(text.contains(today[lang]!), "\(lang) About does not name \(today[lang]!): \(text)")
        }
        for lang in ["en", "en-US", "en-CA"] {
            #expect(!about[lang]!.contains("no network requests"))
            #expect(!AboutCopy.values("about.itAlsoIncludesReckless")[lang]!.contains("no network requests"))
        }
    }
}

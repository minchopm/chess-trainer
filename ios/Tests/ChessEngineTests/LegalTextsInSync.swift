import Foundation
import Testing

/// The licence and the notices the app shows are the ones at the root of the
/// repository.
///
/// They are copies — a bundle cannot reach a Markdown file outside itself, so
/// `sync-legal.sh` puts plain-text duplicates in `Resources/Legal` — and a copy
/// is only right until the original changes. These had drifted: the root said
/// the application is AGPLv3 while the app, under About → Read the full
/// licence, showed the GPLv3 text, and its notice said the whole application
/// was GPLv3. Nothing failed; the wrong licence simply shipped. Licence texts
/// are the one place where "nearly the same" is not the same.
@Suite("The licence texts in the app")
struct LegalTextsInSync {
    static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()   // ChessEngineTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // ios
        .deletingLastPathComponent()   // the repository

    @Test("match the originals", arguments: [
        ("LICENSE", "ios/Resources/Legal/LICENSE.txt"),
        ("NOTICE.md", "ios/Resources/Legal/NOTICE.txt"),
        ("ios/Vendor/Reckless/LICENSE", "ios/Resources/Legal/AGPL.txt"),
    ])
    func matchTheOriginals(original: String, copy: String) throws {
        let a = try Data(contentsOf: Self.root.appending(path: original))
        let b = try Data(contentsOf: Self.root.appending(path: copy))
        #expect(a == b, "\(copy) is out of date with \(original) — run ios/scripts/sync-legal.sh")
    }

    /// And the one the app calls its licence is the Affero one, because that is
    /// what the whole application carries once Reckless is linked in.
    @Test("the app's licence is the AGPL")
    func licenceIsTheAffero() throws {
        let text = try String(contentsOf: Self.root.appending(path: "ios/Resources/Legal/LICENSE.txt"), encoding: .utf8)
        #expect(text.contains("GNU AFFERO GENERAL PUBLIC LICENSE"))
    }
}

import SwiftUI
import ChessTraining

/// Licence and attribution, reachable from inside the app.
///
/// This is not decoration. The app links Stockfish, which is GPLv3, so the
/// licence terms and the offer of source have to reach the person holding the
/// phone — not just someone who thinks to look up the repository.
struct AboutScreen: View {
    private static let sourceURL = "https://github.com/minchopm/chess-trainer"

    /// Apple's standard licence agreement, which applies unless a custom EULA
    /// is filed in App Store Connect. Linked from the paywall because a price
    /// shown without terms is a rejection waiting to happen.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://github.com/minchopm/chess-trainer/blob/main/PRIVACY.md")!

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.t("about.chessTrainer", "Chess Trainer")).font(.title2.weight(.semibold))
                    Text(L.t("about.version", "Version %@", Self.version)).font(.footnote).foregroundStyle(.secondary)
                    Text(L.t("about.tacticsPositionalJudgementEndgameTechnique", "Tactics, positional judgement, endgame technique and coached play, with Stockfish running on the device. Nothing leaves the phone."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }

            Section(L.t("about.licence", "Licence")) {
                Text(L.t("about.thisApplicationIsFreeSoftware", "This application is free software, licensed under the GNU General Public License version 3 or later."))
                    .font(.footnote)
                Text(L.t("about.itIncludesStockfishWhichIs", "It includes Stockfish, which is GPLv3. Because Stockfish is linked into the app, the whole application carries the same licence — and its complete source is published."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                NavigationLink("Read the full licence") {
                    BundledTextView(resource: "LICENSE", title: L.t("about.gnuGplV3", "GNU GPL v3"))
                }
                NavigationLink("Third-party components") {
                    BundledTextView(resource: "NOTICE", title: L.t("about.attribution", "Attribution"))
                }
                Link("Source code", destination: URL(string: Self.sourceURL)!)
            }

            Section(L.t("about.credits", "Credits")) {
                credit(
                    "Stockfish",
                    "The chess engine. Copyright © 2004–2026 the Stockfish developers. GPLv3.",
                    "https://stockfishchess.org"
                )
                credit(
                    "Lichess puzzle database",
                    "Most of the bundled puzzles, with ratings from millions of human attempts. Released under CC0.",
                    "https://database.lichess.org"
                )
            }

            Section(L.t("about.privacy", "Privacy")) {
                Text(L.t("about.theAppCollectsNothingSends", "The app collects nothing, sends nothing and makes no network requests. Your ratings and history are stored only on this device, and deleting the app deletes them."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L.t("about.about", "About"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func credit(_ name: String, _ description: String, _ url: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.subheadline.weight(.medium))
            Text(description).font(.footnote).foregroundStyle(.secondary)
            if let link = URL(string: url) {
                Link(url.replacingOccurrences(of: "https://", with: ""), destination: link)
                    .font(.footnote)
            }
        }
        .padding(.vertical, 2)
    }

    static var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

/// Shows a text file shipped in the bundle.
///
/// The GPL is 674 lines, so it is rendered lazily and as plain monospaced text
/// rather than pushed through anything that tries to lay it out prettily.
struct BundledTextView: View {
    let resource: String
    let title: String

    @State private var text: String?

    var body: some View {
        ScrollView {
            if let text {
                Text(text)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ProgressView().padding(40)
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            guard text == nil else { return }
            text = Self.load(resource) ?? "The licence text is missing from this build. It is also available at https://www.gnu.org/licenses/gpl-3.0.txt"
        }
    }

    static func load(_ resource: String) -> String? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return contents
    }
}

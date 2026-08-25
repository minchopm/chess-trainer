import ChessTraining
import SwiftUI

/// Licence and attribution, rendered with the same panels and navigation as
/// the rest of the app rather than a platform List or NavigationLink.
struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var document: LegalDocument?

    private static let sourceURL = "https://github.com/minchopm/chess-trainer"
    /// Forwarded to a real inbox rather than answered by a mailbox nobody
    /// watches. Two addresses because a request about somebody's data
    /// arrives on a deadline and a question about a puzzle does not.
    private static let supportEmail = "support@brasspawn.com"
    private static let privacyEmail = "privacy@brasspawn.com"

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://brasspawn.com/privacy")!

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("about.about", "About")) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Panel {
                        Text(L.t("about.brassPawn", "Brass Pawn"))
                            .appFont(size: 25, weight: .semibold)
                            .foregroundStyle(Theatre.ivory)
                        Text(L.t("about.version", "Version %@", Self.version))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryDim)
                        Text(L.t("about.tacticsPositionalJudgementEndgameTechnique", "Tactics, positional judgement, endgame technique and coached play, with the engine running on the device. Nothing leaves the phone."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
                    }

                    aboutSection(L.t("about.licence", "Licence")) {
                        Text(L.t("about.thisApplicationIsFreeSoftware", "This application is free software, licensed under the GNU General Public License version 3 or later."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivory)
                        Text(L.t("about.itIncludesStockfishWhichIs", "It includes Stockfish, which is GPLv3. Because Stockfish is linked into the app, the whole application carries the same licence — and its complete source is published."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
                        Text(L.t("about.itAlsoIncludesReckless", "It also includes Reckless, a second engine, which is AGPLv3. The two licences combine, and the Affero clause about software used over a network changes nothing here: both engines run on this device and the app makes no network requests."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)

                        documentButton("Read the full licence", resource: "LICENSE", title: L.t("about.gnuGplV3", "GNU GPL v3"))
                        documentButton("Read the Affero licence", resource: "AGPL", title: L.t("about.gnuAgplV3", "GNU AGPL v3"))
                        documentButton("Third-party components", resource: "NOTICE", title: L.t("about.attribution", "Attribution"))
                        BrassLinkButton(title: "Source code", destination: URL(string: Self.sourceURL)!)
                            .appFont(.footnote)
                    }

                    aboutSection(L.t("about.credits", "Credits")) {
                        credit(
                            "Stockfish",
                            "A chess engine. Copyright © 2004–2026 the Stockfish developers. GPLv3.",
                            "https://stockfishchess.org"
                        )
                        Divider().overlay(Theatre.ruleSoft)
                        credit(
                            "Reckless",
                            "The other chess engine. Copyright © the Reckless developers. AGPLv3.",
                            "https://github.com/codedeliveryservice/Reckless"
                        )
                        Divider().overlay(Theatre.ruleSoft)
                        credit(
                            "Lichess puzzle database",
                            "Most of the bundled puzzles, with ratings from millions of human attempts. Released under CC0.",
                            "https://database.lichess.org"
                        )
                        Divider().overlay(Theatre.ruleSoft)
                        credit(
                            "Cormorant Garamond & JetBrains Mono",
                            "The typefaces. Copyright 2015 the Cormorant Project Authors and 2020 the JetBrains Mono Project Authors. SIL Open Font License 1.1.",
                            "https://github.com/CatharsisFonts/Cormorant"
                        )
                    }

                    aboutSection(L.t("about.privacy", "Privacy")) {
                        Text(L.t("about.theAppCollectsNothingSends", "The app collects nothing, sends nothing and makes no network requests. Your ratings and history are stored only on this device, and deleting the app deletes them."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
                        BrassLinkButton(
                            title: Self.privacyEmail,
                            destination: URL(string: "mailto:\(Self.privacyEmail)")!
                        )
                    }

                    aboutSection(L.t("about.contact", "Contact")) {
                        Text(L.t("about.somethingWrongOrMissing", "Something wrong, or missing? There is somebody at the other end of this."))
                            .appFont(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
                        BrassLinkButton(
                            title: Self.supportEmail,
                            destination: URL(string: "mailto:\(Self.supportEmail)")!
                        )
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .fullScreenCover(item: $document) { item in
            BundledTextView(resource: item.resource, title: item.title)
        }
    }

    private func aboutSection<Content: View>(
        _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Slug(text: title)
            Panel { content() }
        }
    }

    private func documentButton(_ label: String, resource: String, title: String) -> some View {
        Button {
            document = LegalDocument(resource: resource, title: title)
        } label: {
            HStack {
                Text(label).appFont(.subheadline).foregroundStyle(Theatre.ivory)
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption2)
                    .foregroundStyle(Theatre.ivoryFaint)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                BrassPlateShape(cut: 7).fill(Theatre.ink3)
            }
            .overlay {
                BrassPlateShape(cut: 7)
                    .strokeBorder(Theatre.brassDeep.opacity(0.44), lineWidth: 0.65)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(BrassPressStyle())
    }

    private func credit(_ name: String, _ description: String, _ url: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).appFont(.subheadline, weight: .medium).foregroundStyle(Theatre.ivory)
            Text(description).appFont(.footnote).foregroundStyle(Theatre.ivoryFaint)
            if let link = URL(string: url) {
                BrassLinkButton(
                    title: url.replacingOccurrences(of: "https://", with: ""),
                    destination: link
                )
                .appFont(.footnote)
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

private struct LegalDocument: Identifiable {
    let resource: String
    let title: String
    var id: String { resource }
}

struct BundledTextView: View {
    @Environment(\.dismiss) private var dismiss
    let resource: String
    let title: String

    @State private var text: String?

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: title) { dismiss() }

            ScrollView {
                if let text {
                    Text(text)
                        .appFont(size: 11)
                        .textSelection(.enabled)
                        .foregroundStyle(Theatre.ivoryDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    BrassActivityIndicator().padding(40)
                }
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .task {
            guard text == nil else { return }
            // The fallback names the right licence: there are two of them now,
            // and pointing somebody at the GPL when they asked for the Affero
            // one is worse than saying nothing.
            let url = resource == "AGPL"
                ? "https://www.gnu.org/licenses/agpl-3.0.txt"
                : "https://www.gnu.org/licenses/gpl-3.0.txt"
            text = Self.load(resource)
                ?? "The licence text is missing from this build. It is also available at \(url)"
        }
    }

    static func load(_ resource: String) -> String? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return contents
    }
}

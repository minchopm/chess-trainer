import ChessTraining
import SwiftUI

/// Licence and attribution, rendered with the same panels and navigation as
/// the rest of the app rather than a platform List or NavigationLink.
struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var document: LegalDocument?

    private static let sourceURL = "https://github.com/minchopm/chess-trainer"

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://brasspawn.com/privacy")!

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("about.about", "About")) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Panel {
                        Text(L.t("about.brassPawn", "Brass Pawn"))
                            .font(Face.display(25))
                            .foregroundStyle(Theatre.ivory)
                        Text(L.t("about.version", "Version %@", Self.version))
                            .font(.footnote)
                            .foregroundStyle(Theatre.ivoryDim)
                        Text(L.t("about.tacticsPositionalJudgementEndgameTechnique", "Tactics, positional judgement, endgame technique and coached play, with Stockfish running on the device. Nothing leaves the phone."))
                            .font(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
                    }

                    aboutSection(L.t("about.licence", "Licence")) {
                        Text(L.t("about.thisApplicationIsFreeSoftware", "This application is free software, licensed under the GNU General Public License version 3 or later."))
                            .font(.footnote)
                            .foregroundStyle(Theatre.ivory)
                        Text(L.t("about.itIncludesStockfishWhichIs", "It includes Stockfish, which is GPLv3. Because Stockfish is linked into the app, the whole application carries the same licence — and its complete source is published."))
                            .font(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)

                        documentButton("Read the full licence", resource: "LICENSE", title: L.t("about.gnuGplV3", "GNU GPL v3"))
                        documentButton("Third-party components", resource: "NOTICE", title: L.t("about.attribution", "Attribution"))
                        BrassLinkButton(title: "Source code", destination: URL(string: Self.sourceURL)!)
                            .font(.footnote)
                    }

                    aboutSection(L.t("about.credits", "Credits")) {
                        credit(
                            "Stockfish",
                            "The chess engine. Copyright © 2004–2026 the Stockfish developers. GPLv3.",
                            "https://stockfishchess.org"
                        )
                        Divider().overlay(Theatre.ruleSoft)
                        credit(
                            "Lichess puzzle database",
                            "Most of the bundled puzzles, with ratings from millions of human attempts. Released under CC0.",
                            "https://database.lichess.org"
                        )
                    }

                    aboutSection(L.t("about.privacy", "Privacy")) {
                        Text(L.t("about.theAppCollectsNothingSends", "The app collects nothing, sends nothing and makes no network requests. Your ratings and history are stored only on this device, and deleting the app deletes them."))
                            .font(.footnote)
                            .foregroundStyle(Theatre.ivoryFaint)
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
                Text(label).font(.subheadline).foregroundStyle(Theatre.ivory)
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
            Text(name).font(.subheadline.weight(.medium)).foregroundStyle(Theatre.ivory)
            Text(description).font(.footnote).foregroundStyle(Theatre.ivoryFaint)
            if let link = URL(string: url) {
                BrassLinkButton(
                    title: url.replacingOccurrences(of: "https://", with: ""),
                    destination: link
                )
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
                        .font(.system(size: 11, design: .monospaced))
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

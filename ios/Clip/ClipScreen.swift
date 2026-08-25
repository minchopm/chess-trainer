import BoardUI
import ChessCore
import ChessTraining
import StoreKit
import SwiftUI

/// The clip, entire: a caption, a board, a line of verdict, and one button that
/// never leaves the screen.
///
/// Deliberately one screen with no navigation. Whoever opened this tapped a
/// link in a message, and the whole of what they want to know — is this any
/// good — has to be answerable without them going anywhere.
struct ClipScreen: View {
    @Bindable var model: ClipModel
    @State private var showsStoreOverlay = false

    var body: some View {
        ZStack {
            Theatre.ink.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .appStoreOverlay(isPresented: $showsStoreOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
        .onChange(of: model.shouldOfferApp) { _, offer in
            guard offer else { return }
            showsStoreOverlay = true
            model.offerWasShown()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            if model.isFinished {
                finished
            } else {
                board
            }
            Spacer(minLength: 8)
            footer
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The name, because a clip opens from a link in somebody's messages
            // and the first question is what this is. Verbatim: it is a name,
            // and names are not translated.
            Text(verbatim: "Brass Pawn")
                .font(.custom("CormorantGaramond-SemiBold", size: 30))
                .foregroundStyle(Theatre.ivory)

            if let invitation = model.invitation {
                Text(L.t("clip.invitedYou", "%@ invited you to a game.", invitation.name))
                    .appFont(size: 14)
                    .foregroundStyle(Theatre.brass)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !model.isFinished {
                HStack(alignment: .firstTextBaseline) {
                    Slug(text: L.t("tactics.puzzle", "Puzzle"), trailingRule: false)
                    Text(verbatim: "\(model.index + 1)/\(model.puzzles.count)")
                        .appFont(size: 11)
                        .monospacedDigit()
                        .foregroundStyle(Theatre.ivoryFaint)
                    Spacer()
                    Text(objective)
                        .appFont(size: 12)
                        .foregroundStyle(Theatre.ivoryDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.top, 12)
    }

    /// What the puzzle asks for. The same reading of the themes the app makes,
    /// so the clip and the app describe the same position the same way.
    private var objective: String {
        guard let puzzle = model.puzzle else { return "" }
        let themes = Set(puzzle.themes)
        if puzzle.mate || themes.contains("mate") {
            if let inN = puzzle.themes.first(where: { $0.hasPrefix("mateIn") }) {
                return L.t("tactics.mateIn", "Mate in %@.", String(inN.dropFirst("mateIn".count)))
            }
            return L.t("tactics.findForcedMate", "Find the forced mate.")
        }
        if themes.contains("winsMaterial") || themes.contains("hangingPiece") {
            return L.t("tactics.winMaterial", "Win material.")
        }
        if themes.contains("crushing") { return L.t("tactics.crushingBlow", "Find the crushing blow.") }
        return L.t("tactics.strongestContinuation", "Find the strongest continuation.")
    }

    // MARK: - Board

    @ViewBuilder
    private var board: some View {
        VStack(spacing: 14) {
            BoardView(
                position: model.position,
                orientation: model.puzzle?.sideToMove ?? .white,
                legalDestinations: model.legalDestinations,
                lastMove: model.lastMove,
                onMove: { from, to, kind in model.play(from: from, to: to, promotion: kind) }
            )
            .frame(maxWidth: 520)

            verdict
                .frame(height: 22)

            // What the puzzle is made of, once it has been solved. Withheld
            // until then because "knight fork" is half the answer.
            Text(motifs)
                .appFont(size: 11)
                .tracking(1.6)
                .foregroundStyle(Theatre.ivoryFaint)
                .opacity(model.verdict == .solved ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: model.verdict)
                .frame(height: 14)
        }
    }

    private var motifs: String {
        guard let puzzle = model.puzzle else { return "" }
        return puzzle.themes
            .filter(Themes.isMotif)
            .prefix(3)
            .map { Themes.readable($0).uppercased() }
            .joined(separator: " · ")
    }

    @ViewBuilder
    private var verdict: some View {
        switch model.verdict {
        case .solved:
            Text(L.t("tactics.solved", "Solved"))
                .appFont(size: 14)
                .foregroundStyle(Theatre.good)
                .transition(.opacity)
                .task(id: model.index) {
                    try? await Task.sleep(for: .milliseconds(900))
                    withAnimation { model.advance() }
                }
        case .wrong:
            Text(L.t("common.tryAgain", "Try again"))
                .appFont(size: 14)
                .foregroundStyle(Theatre.warn)
        case .waiting:
            Text(model.isBusy
                ? L.t("tactics.opponentReplies", "Opponent replies…")
                : L.t("common.sideToPlay", "%@ to play", L.color(model.position.sideToMove)))
                .appFont(size: 13)
                .foregroundStyle(Theatre.ivoryFaint)
        }
    }

    // MARK: - The end of the demonstration

    private var finished: some View {
        Panel {
            Text(L.t("clip.thatIsTheSample", "That was six of them"))
                .appFont(size: 20)
                .foregroundStyle(Theatre.ivory)
                .padding(.bottom, 2)
            Text(L.t(
                "clip.fourteenThousandMore",
                "Brass Pawn has fourteen thousand more, chosen from what you have been finding hard rather than at random — and an engine that tells you what the stronger move was worth."
            ))
            .appFont(size: 14)
            .foregroundStyle(Theatre.ivoryDim)
            if model.invitation != nil {
                Text(L.t(
                    "clip.invitationKept",
                    "The invitation is kept. Install the app and it will be waiting."
                ))
                .appFont(size: 13)
                .foregroundStyle(Theatre.brass)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Footer

    /// The one control, and it is on screen from the first second to the last.
    /// Somebody who decides at puzzle two that they want the app should not
    /// have to finish puzzle six to be told where it is.
    private var footer: some View {
        Button {
            showsStoreOverlay = true
        } label: {
            Text(L.t("clip.getTheApp", "Get Brass Pawn"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
        .frame(maxWidth: 520)
    }
}

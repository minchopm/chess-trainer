import SwiftUI
import ChessTraining

/// The moment a puzzle, drill or game ends.
struct CompletionResult: Equatable {
    enum Verdict: Equatable { case success, partial, failure }

    let verdict: Verdict
    let title: String
    let detail: String?
    /// The line played, in notation, when there is one worth showing.
    let line: String?

    var symbol: String {
        switch verdict {
        case .success: "checkmark.circle.fill"
        case .partial: "checkmark.circle"
        case .failure: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch verdict {
        case .success: Theatre.good
        case .partial: Theatre.warn
        case .failure: Theatre.bad
        }
    }
}

/// Announces a finished exercise or game as a focused, full-screen modal
/// moment. The dimmed board remains visible as context, but it no longer
/// competes with a result card compressed against the bottom controls.
struct CompletionOverlay: View {
    let result: CompletionResult
    let primaryTitle: String
    let onPrimary: () -> Void
    let onRetry: (() -> Void)?
    let replayTitle: String?
    let onReplay: (() -> Void)?

    @State private var hasAppeared = false

    init(
        result: CompletionResult,
        primaryTitle: String,
        onPrimary: @escaping () -> Void,
        onRetry: (() -> Void)? = nil,
        replayTitle: String? = nil,
        onReplay: (() -> Void)? = nil
    ) {
        self.result = result
        self.primaryTitle = primaryTitle
        self.onPrimary = onPrimary
        self.onRetry = onRetry
        self.replayTitle = replayTitle
        self.onReplay = onReplay
    }

    var body: some View {
        BrassModalBackdrop {
            BrassModalPanel(tint: result.tint) {
                HStack(spacing: 11) {
                    BrassIcon(result.symbol, size: 30)
                        .foregroundStyle(result.tint)
                        .symbolEffect(.bounce, value: hasAppeared)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.title).appFont(size: 24, weight: .semibold)
                        if let detail = result.detail {
                            Text(detail)
                                .appFont(.subheadline)
                                .foregroundStyle(Theatre.ivoryDim)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if let line = result.line {
                    ScrollView {
                        Text(line)
                            .appFont(.subheadline)
                            .foregroundStyle(Theatre.ivoryDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxHeight: 220)
                }

                if let replayTitle, let onReplay {
                    Button(action: onReplay) {
                        Label {
                            Text(replayTitle)
                        } icon: {
                            BrassIcon("play.rectangle", size: 18)
                        }
                        .appFont(.body, weight: .semibold)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                }

                HStack(spacing: 10) {
                    if let onRetry {
                        Button(L.t("common.tryAgain", "Try again"), action: onRetry)
                            .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                            .frame(maxWidth: .infinity)
                    }
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear { hasAppeared = true }
    }
}

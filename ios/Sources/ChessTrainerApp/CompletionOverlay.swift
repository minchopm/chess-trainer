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

/// Announces the result without hiding the board.
///
/// A centred modal would be the obvious choice and the wrong one: the board is
/// showing the solution played out, and that is the part worth looking at. So
/// this sits at the bottom, over the controls rather than over the position,
/// and puts the next action under the thumb.
struct CompletionOverlay: View {
    let result: CompletionResult
    let primaryTitle: String
    let onPrimary: () -> Void
    let onRetry: (() -> Void)?

    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: result.symbol)
                    .font(.title2)
                    .foregroundStyle(result.tint)
                    .symbolEffect(.bounce, value: hasAppeared)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title).font(Face.display(24))
                    if let detail = result.detail {
                        Text(detail).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            if let line = result.line {
                Text(line)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                if let onRetry {
                    Button(L.t("common.tryAgain", "Try again"), action: onRetry)
                        .buttonStyle(PillButtonStyle(emphasis: .ghost))
                }
                Button(primaryTitle, action: onPrimary)
                    .buttonStyle(PillButtonStyle(emphasis: .solid))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Theatre.ink2.opacity(0.98), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theatre.rule, lineWidth: 0.5))
        .overlay(alignment: .top) {
            Rectangle().fill(result.tint).frame(height: 3)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
        .padding(.horizontal, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear { hasAppeared = true }
    }
}

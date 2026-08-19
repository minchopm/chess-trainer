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
        case .success: Color(red: 0.29, green: 0.70, blue: 0.36)
        case .partial: Color(red: 0.87, green: 0.68, blue: 0.25)
        case .failure: Color(red: 0.85, green: 0.36, blue: 0.31)
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
                    Text(result.title).font(.headline)
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
                        .buttonStyle(.bordered)
                }
                Button(primaryTitle, action: onPrimary)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
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

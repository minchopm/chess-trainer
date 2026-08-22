import ChessCore
import ChessTraining
import SwiftData
import SwiftUI

/// The games you played, newest first.
///
/// A separate list rather than a shelf of the classics library: the library is
/// built around `ClassicGame` and these are not that, and the two are sorted
/// and searched by different things. What they do share is the viewer — a game
/// of yours is watched with the same transport as anybody else's.
struct HistoryList: View {
    @Environment(AppModel.self) private var app
    @Environment(Navigator.self) private var navigator
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedGame.playedAt, order: .reverse) private var games: [SavedGame]

    @State private var watching: SavedGame?

    var body: some View {
        Group {
            if games.isEmpty {
                empty
            } else {
                ScrollView {
                    LazyVStack(spacing: -1) {
                        ForEach(games) { game in
                            Button { watching = game } label: { row(game) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $watching) { game in
            SavedGameViewer(game: game)
        }
        #endif
    }

    private var empty: some View {
        VStack(spacing: 8) {
            BrassIcon("clock.arrow.circlepath", size: 26)
                .foregroundStyle(Theatre.brass.opacity(0.7))
            Text(L.t("history.none", "Games you play are kept here."))
                .appFont(.footnote)
                .foregroundStyle(Theatre.ivoryDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func row(_ game: SavedGame) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(game.players)
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                Text(subtitle(game))
                    .appFont(.caption)
                    .foregroundStyle(Theatre.ivoryDim)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(resultText(game))
                .appFont(.caption, weight: .medium)
                .foregroundStyle(resultColour(game))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The same plate the library's own rows are cut from: a game of yours
        // is a game like any other in the list it sits beside.
        .background {
            BrassPlateShape(cut: 10).fill(LinearGradient(
                colors: [Theatre.ink3, Theatre.ink2],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
        .overlay {
            BrassPlateShape(cut: 10)
                .strokeBorder(Theatre.brassDeep.opacity(0.45), lineWidth: 0.65)
        }
    }

    private func subtitle(_ game: SavedGame) -> String {
        let when = game.playedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(when) · \(L.t("watch.moveCount", "%lld moves", game.moveCount))"
    }

    /// The result from your side, because that is the side you remember it
    /// from. A game between two engines has no such side and says the score.
    private func resultText(_ game: SavedGame) -> String {
        switch game.result {
        case "win": L.t("history.won", "Won")
        case "loss": L.t("history.lost", "Lost")
        case "draw": L.t("history.drew", "Drawn")
        default: game.result
        }
    }

    private func resultColour(_ game: SavedGame) -> Color {
        switch game.result {
        case "win": Theatre.brass
        case "loss": Color(red: 0.851, green: 0.439, blue: 0.373)
        default: Theatre.ivoryDim
        }
    }
}

/// One of your games, in the viewer the classics use.
private struct SavedGameViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @Environment(Navigator.self) private var navigator

    let game: SavedGame

    var body: some View {
        ReplayViewer(
            title: game.players,
            subtitle: subtitle,
            startingPosition: game.startPosition,
            notation: game.notation,
            startAt: app.progress.watchMark(for: game.id)?.ply ?? 0,
            onProgress: { ply, total in
                app.update { $0.mark(watched: game.id, ply: ply, of: total) }
            },
            onContinue: { ply in
                navigator.continueOnBoard(BoardHandoff(
                    title: game.players,
                    start: game.startPosition,
                    moves: Array(game.moves.prefix(ply))
                ))
                dismiss()
            },
            onDismiss: { dismiss() }
        )
    }

    private var subtitle: String {
        let when = game.playedAt.formatted(date: .abbreviated, time: .shortened)
        guard let elo = game.opponentElo else { return when }
        return "\(when) · \(elo)"
    }
}

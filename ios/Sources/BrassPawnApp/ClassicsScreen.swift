import ChessTraining
import SwiftUI

/// The games on offer.
///
/// Nine hundred of them, and none of them a grind: every one is decisive,
/// between two named players, and either finished inside twenty-five moves or
/// is one of the games that has a name of its own. What is left when you throw
/// away the seventy-move endgame technique is the part people replay.
struct ClassicsScreen: View {
    @Environment(AppModel.self) private var app
    var showsHeader = true
    @State private var query = ""
    @State private var showsAll = false
    @State private var watching: ClassicGame?

    private var games: [ClassicGame] {
        let all = app.library.classics
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        let matching = text.isEmpty ? all : all.filter { $0.haystack.contains(text) }
        if !text.isEmpty || showsAll { return matching }
        return matching.filter(\.notable)
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader {
                TopBar {
                    Text(L.t("progress.watch", "Watch"))
                        .appFont(size: 20, weight: .semibold)
                        .foregroundStyle(Theatre.ivory)
                        .frame(maxWidth: .infinity)
                }
            }

            search
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

            if app.library.classics.isEmpty {
                LibraryNotice(isLoaded: app.isLibraryLoaded,
                              what: L.t("watch.games", "games"), file: "classics.json")
                    .frame(maxHeight: .infinity)
            } else {
                if query.isEmpty {
                    gameFilter
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)
                }

                list
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        // Full screen rather than pushed: a recording is not a page of the
        // library, and the tab bar underneath a transport bar is two rows of
        // controls that mean different things.
        #if os(iOS)
        .fullScreenCover(item: $watching) { game in
            WatchScreen(game: game)
        }
        #endif
        .task(id: app.library.classics.count) {}
    }

    private var search: some View {
        BrassSearchField(
            placeholder: L.t("watch.search", "Player, event or year"),
            text: $query
        )
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // The imported collection can contain different games with
                // the same players, year and move count.  Its legacy `id`
                // does not distinguish those scores, which makes LazyVStack
                // merge two rows and leave a large blank placeholder behind.
                // The complete value includes the moves, so every real score
                // has a stable, distinct identity in this list.
                ForEach(games, id: \.self) { game in
                    Button { watching = game } label: { row(game) }
                        .buttonStyle(BrassPressStyle())
                }

                if games.isEmpty {
                    Text(L.t("watch.nothingFound", "No game matches that."))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .padding(.top, 30)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 90)
        }
    }

    private var gameFilter: some View {
        BrassSegmentedPicker(
            L.t("watch.games", "Games"),
            selection: $showsAll,
            options: [false, true],
            usesPlainLabels: true
        ) { all in
            Text(all
                ? L.t("watch.everything", "Everything")
                : L.t("watch.named", "Named games"))
        }
    }

    private func row(_ game: ClassicGame) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(game.players)
                    .appFont(size: 17, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                Text(game.occasion)
                    .appFont(size: 9).tracking(1.3)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(L.t("watch.moveCount", "%lld moves", game.moveCount))
                .appFont(size: 9).tracking(1.2)
                .foregroundStyle(Theatre.ivoryDim)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

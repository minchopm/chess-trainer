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
            // No TopBar here: this screen lives inside the Play tab, which
            // already has one, and two avatars in one corner is a bug that
            // looks like a design.
            search
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

            if app.library.classics.isEmpty {
                LibraryNotice(isLoaded: app.isLibraryLoaded,
                              what: L.t("watch.games", "games"), file: "classics.json")
                    .frame(maxHeight: .infinity)
            } else {
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
                if query.isEmpty {
                    BrassSegmentedPicker(
                        L.t("watch.games", "Games"),
                        selection: $showsAll,
                        options: [false, true]
                    ) { all in
                        Text(all
                            ? L.t("watch.everything", "Everything")
                            : L.t("watch.named", "Named games"))
                    }
                    .padding(.bottom, 4)
                }

                ForEach(games) { game in
                    Button { watching = game } label: { row(game) }
                        .buttonStyle(.plain)
                }

                if games.isEmpty {
                    Text(L.t("watch.nothingFound", "No game matches that."))
                        .font(.footnote)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .padding(.top, 30)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 90)
        }
    }

    private func row(_ game: ClassicGame) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(game.players)
                    .font(Face.display(17))
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                Text(game.occasion)
                    .font(Face.mono(9)).tracking(1.3)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(L.t("watch.moveCount", "%lld moves", game.moveCount))
                .font(Face.mono(9)).tracking(1.2)
                .foregroundStyle(Theatre.ivoryDim)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theatre.ink3, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Theatre.rule, lineWidth: 0.5))
    }
}

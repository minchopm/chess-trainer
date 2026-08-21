import ChessTraining
import SwiftUI

/// The games on offer.
///
/// Nine hundred of them, and none of them a grind: every one is decisive,
/// between two named players, and either finished inside twenty-five moves or
/// is one of the games that has a name of its own. What is left when you throw
/// away the seventy-move endgame technique is the part people replay.
struct ClassicsScreen: View {
    /// Which shelf of the library is on show.
    ///
    /// Named games are the front of the shop and what the screen opens on.
    /// The other three are the ones a person builds themselves: everything,
    /// what they have started, and what they have kept.
    private enum Shelf: Hashable, CaseIterable {
        case named, all, watching, kept

        var name: String {
            switch self {
            case .named: L.t("watch.named", "Named games")
            case .all: L.t("watch.everything", "Everything")
            case .watching: L.t("watch.continue", "Continue")
            case .kept: L.t("watch.saved", "Saved")
            }
        }
    }

    /// The order the shelf is put in.
    private enum Order: Hashable, CaseIterable {
        case shortest, year, recent

        var name: String {
            switch self {
            case .shortest: L.t("watch.byLength", "Shortest")
            case .year: L.t("watch.byYear", "Newest")
            case .recent: L.t("watch.byRecent", "Last opened")
            }
        }
    }

    @Environment(AppModel.self) private var app
    var showsHeader = true
    @State private var query = ""
    @State private var shelf = Shelf.named
    @State private var order = Order.shortest
    @State private var watching: ClassicGame?

    private var games: [ClassicGame] {
        let all = app.library.classics
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        var matching = text.isEmpty ? all : all.filter { $0.haystack.contains(text) }

        // A search looks through the whole library; the shelves are what you
        // browse when you are not looking for anything in particular.
        if text.isEmpty {
            switch shelf {
            case .named: matching = matching.filter(\.notable)
            case .all: break
            case .watching:
                matching = matching.filter {
                    guard let mark = app.progress.watchMark(for: $0.id) else { return false }
                    return !mark.isFinished
                }
            case .kept: matching = matching.filter { app.progress.isFavourite($0.id) }
            }
        }
        return sorted(matching)
    }

    private func sorted(_ games: [ClassicGame]) -> [ClassicGame] {
        switch order {
        case .shortest: games            // the order the library arrives in
        case .year: games.sorted { $0.year > $1.year }
        case .recent:
            games.sorted {
                let left = app.progress.watchMark(for: $0.id)?.at ?? .distantPast
                let right = app.progress.watchMark(for: $1.id)?.at ?? .distantPast
                return left > right
            }
        }
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
                sortRow
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)

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
            selection: $shelf,
            options: Shelf.allCases,
            usesPlainLabels: true
        ) { shelf in
            Text(shelf.name)
        }
    }

    /// The order, as a row of words rather than a menu: three options do not
    /// need to be hidden behind a tap.
    private var sortRow: some View {
        HStack(spacing: 8) {
            Text(L.t("watch.sortBy", "Order"))
                .appFont(size: 9).tracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(Theatre.ivoryFaint)
            ForEach(Order.allCases, id: \.self) { option in
                let chosen = order == option
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { order = option }
                } label: {
                    Text(option.name)
                        .appFont(size: 10, weight: chosen ? .semibold : .regular)
                        .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background {
                            Capsule().fill(chosen ? Theatre.brassGlow : Color.clear)
                        }
                        .overlay {
                            Capsule().strokeBorder(
                                chosen ? Theatre.brassDeep.opacity(0.8) : Color.clear,
                                lineWidth: 0.6
                            )
                        }
                }
                .buttonStyle(BrassPressStyle())
            }
            Spacer(minLength: 0)
        }
    }

    private func row(_ game: ClassicGame) -> some View {
        let mark = app.progress.watchMark(for: game.id)
        return VStack(alignment: .leading, spacing: 8) {
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
                keep(game)
            }
            if let mark, mark.ply > 0 { progress(mark) }
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

    /// How far in, as a line under the game.
    ///
    /// A bar rather than "12 of 25": the question this answers is *did I
    /// finish this one*, and the eye reads a length faster than it reads a
    /// fraction. A finished game keeps its line, filled — an empty row would
    /// say the same as one never opened.
    private func progress(_ mark: WatchMark) -> some View {
        HStack(spacing: 7) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theatre.ivory.opacity(0.09))
                    Capsule()
                        .fill(mark.isFinished ? Theatre.brassDeep : Theatre.brass)
                        .frame(width: max(2, geometry.size.width * mark.fraction))
                }
            }
            .frame(height: 2.5)
            Text(mark.isFinished
                 ? L.t("watch.watched", "Watched")
                 : L.t("watch.partway", "%lld%%", Int(mark.fraction * 100)))
                .appFont(size: 8).tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(mark.isFinished ? Theatre.brassDeep : Theatre.brass)
        }
    }

    private func keep(_ game: ClassicGame) -> some View {
        let kept = app.progress.isFavourite(game.id)
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                app.update { $0.toggleFavourite(game.id) }
            }
        } label: {
            BrassIcon(kept ? "star.fill" : "star", size: 13)
                .foregroundStyle(kept ? Theatre.brass : Theatre.ivoryFaint)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(L.t("watch.keep", "Save this game"))
    }
}

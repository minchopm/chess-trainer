import BoardScene
import ChessCore
import ChessTraining
import SwiftUI

/// Today: the finished games from the day's top events.
///
/// The one screen in the app whose contents come from somewhere else, so it is
/// the one screen that says so — at the foot of the list, in a sentence, rather
/// than in a settings page nobody opens. Everything else about it is the app's
/// own: the boards are drawn here, in the player's set, and a story is a way
/// into Watch and the free board rather than a page to read and leave.
struct TodayScreen: View {
    @Environment(TodayFeed.self) private var feed
    @Environment(Navigator.self) private var navigator
    @State private var open: FeedStory?
    /// The move a link asked for, for the story it opened.
    @State private var openAt: Int?

    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                Text(L.t("today.title", "Today"))
                    .appFont(size: 20, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .frame(maxWidth: .infinity)
            }
            content
        }
        .background(Theatre.ink.ignoresSafeArea())
        .task { await feed.refresh() }
        .task(id: "\(navigator.pendingStory ?? "")|\(feed.stories.count)") { openPending() }
        .appCover(item: $open, onDismiss: { openAt = nil }) { story in
            StoryScreen(story: story, replayFrom: openAt)
        }
    }

    /// A story asked for by a link — brasspawn://today/<id>, from the site.
    private func openPending() {
        guard let id = navigator.pendingStory, let story = feed.story(id: id) else { return }
        navigator.pendingStory = nil
        openAt = navigator.pendingPly
        navigator.pendingPly = nil
        open = story
    }

    @ViewBuilder
    private var content: some View {
        if feed.stories.isEmpty {
            VStack(spacing: 14) {
                switch feed.state {
                case .idle, .loading:
                    ProgressView().tint(Theatre.brass)
                    Text(L.t("today.loading", "Fetching today’s games…"))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryDim)
                case .failed:
                    Text(L.t("today.unreachable", "Couldn’t reach brasspawn.com. Check the connection and try again."))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryDim)
                        .multilineTextAlignment(.center)
                    retry
                case .loaded:
                    Text(L.t("today.empty", "No stories yet. They go up after each round of a top event."))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryDim)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            list
        }
    }

    private var retry: some View {
        Button(L.t("common.tryAgain", "Try again")) {
            Task { await feed.refresh(force: true) }
        }
        .buttonStyle(PillButtonStyle(emphasis: .ghost))
    }

    /// The stories by day, newest first — the order they arrive in.
    private var days: [(date: String, stories: [FeedStory])] {
        var days: [(date: String, stories: [FeedStory])] = []
        for story in feed.stories {
            if days.last?.date == story.date {
                days[days.count - 1].stories.append(story)
            } else {
                days.append((story.date, [story]))
            }
        }
        return days
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if feed.state == .failed {
                    Text(L.t("today.offline", "Couldn’t reach brasspawn.com. These are the last stories that arrived."))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .padding(.horizontal, 4)
                }
                ForEach(days, id: \.date) { day in
                    // Not `Slug`: its rule takes half the row, and a weekday
                    // and a month in German do not fit in the other half.
                    Text(dayName(day.date).uppercased())
                        .appFont(size: 10)
                        .tracking(3)
                        .foregroundStyle(Theatre.brass)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 12)
                        .padding(.horizontal, 2)
                    ForEach(day.stories) { story in
                        Button { open = story } label: { row(story) }
                            .buttonStyle(BrassPressStyle())
                    }
                }
                if !feed.unreadDays.isEmpty {
                    // Reaching the foot of the list is asking for the day
                    // before; a button would be one more thing to press.
                    ProgressView()
                        .tint(Theatre.brass)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .onAppear { Task { await feed.loadEarlier() } }
                        .id(feed.unreadDays.first?.date)
                }
                Text(L.t("today.privacy", "Opening Today downloads the latest games from brasspawn.com, and earlier days as you scroll back. Nothing about you is sent, and nothing is kept."))
                    .appFont(.caption2)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .padding(.top, 18)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 90)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await feed.refresh(force: true) }
    }

    /// "Friday 25 September", in the reader's language — read in UTC, which is
    /// the calendar the feed's dates are written in, so a reader in New York
    /// does not see Friday's round filed under Thursday.
    private func dayName(_ iso: String) -> String {
        guard let day = FeedStory.dayFormatter.date(from: iso) else { return iso }
        var style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        style.timeZone = TimeZone(identifier: "UTC")!
        return day.formatted(style)
    }

    private func row(_ story: FeedStory) -> some View {
        let focus = story.focus
        return HStack(alignment: .top, spacing: 13) {
            BoardView(position: focus.position,
                      orientation: story.winner == .black ? .black : .white,
                      lastMove: focus.lastMove.map { ($0.from, $0.to) })
                .environment(\.showsBoardCoordinates, false)
                // Glyphs rather than the carved set. The photographed pieces
                // stand a third of a square wide, which is right on a board
                // and a speck on a thumbnail; the glyphs fill the square at any
                // size. The story itself opens on the player's own set.
                .environment(\.pieceSet, .glyph)
                .frame(width: 106, height: 106)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(story.occasion.uppercased())
                    .appFont(size: 8).tracking(1.4)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .lineLimit(1)
                Text(Self.isEnglish ? story.headline : story.title)
                    .appFont(size: 16, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Text(verbatim: "\(story.white.short) \(story.resultText) \(story.black.short)")
                    .appFont(size: 10, weight: .medium).tracking(0.8)
                    .foregroundStyle(Theatre.brass)
                    .lineLimit(1)
                if let key = story.key {
                    Text(L.t("today.keyMove", "Key move: %@", FeedStory.label(ply: key.ply, san: key.played)))
                        .appFont(size: 10)
                        .foregroundStyle(Theatre.ivoryDim)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
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

    /// Whether the reader is reading the app in English, in which case the
    /// written headline says more than the one the app can build.
    static var isEnglish: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? true
    }
}

extension FeedStory {
    /// 1–0, 0–1, ½–½.
    var resultText: String {
        switch result {
        case "1-0": "1–0"
        case "0-1": "0–1"
        default: "½–½"
        }
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

/// One story: the board at the moment it turned, the words, and the two ways
/// into the game the app has — watching it, and taking it over.
struct StoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @Environment(Navigator.self) private var navigator
    @Environment(\.boardTheme) private var boardTheme
    @Environment(\.pieceSet) private var pieceSet

    let story: FeedStory
    /// Where the reader had got to on the site, when a link brought them: the
    /// story opens straight into the replay from that move.
    var replayFrom: Int? = nil

    @State private var replaying = false
    @State private var handedOver = false
    @State private var shareImage: Image?

    private var orientation: PieceColor { story.winner == .black ? .black : .white }

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: story.title, subtitle: story.occasion) { dismiss() }

            // Side by side on an iPad in landscape and in a Mac window, as
            // every other board screen is: the board gets the height, and the
            // reading gets a column beside it instead of a scroll under it.
            // Not on an iPad held upright, which is wide enough and was left
            // with half its screen empty under two short columns.
            GeometryReader { geometry in
                if geometry.size.width >= 820 && geometry.size.width > geometry.size.height {
                    let side = min(geometry.size.width * 0.56, geometry.size.height - 110)
                    HStack(alignment: .top, spacing: 28) {
                        VStack(spacing: 0) {
                            board.frame(width: side, height: side)
                            caption
                            actions.padding(.vertical, 12)
                        }
                        .frame(width: side)
                        reading
                            .frame(maxWidth: 560)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        board
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 10)
                        caption
                        actions
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        reading
                    }
                }
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .onAppear {
            // Once: back out of the replay and the story is there to read,
            // rather than the replay opening again on top of it.
            guard replayFrom != nil, !handedOver else { return }
            handedOver = true
            replaying = true
        }
        .task {
            // After the screen is up rather than before: the round board's
            // still is a full SceneKit render, and made on the way in it held
            // the story back for the length of it.
            try? await Task.sleep(for: .milliseconds(350))
            renderShareImage()
        }
        .appCover(isPresented: $replaying) {
            ReplayViewer(
                title: story.title,
                subtitle: story.occasion,
                startingPosition: Position(),
                notation: story.moves,
                // One move before the one the story is about, so the reader
                // sees it played rather than finds it already on the board —
                // or, handed over from the site, the move they had reached.
                startAt: replayFrom ?? max(0, story.focusPly - 1),
                onContinue: { ply in
                    replaying = false
                    carryOn(from: ply)
                },
                onDismiss: { replaying = false }
            )
        }
    }

    private var board: some View {
        let focus = story.focus
        return GameBoard(position: focus.position,
                         orientation: orientation,
                         lastMove: focus.lastMove.map { ($0.from, $0.to) })
    }

    @ViewBuilder
    private var caption: some View {
        if let key = story.key {
            Text(verbatim: L.t("today.after", "After %@", FeedStory.label(ply: key.ply, san: key.played))
                 + " · " + L.t("today.stockfish", "Stockfish %1$@ → %2$@", key.before.text, key.after.text))
                .appFont(size: 10).tracking(0.8)
                .foregroundStyle(Theatre.ivoryFaint)
                .padding(.top, 8)
        }
    }

    private var reading: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                words
                facts
                Text(L.t("today.source", "Moves from the official broadcast, relayed by Lichess. Evaluations by Stockfish. Brass Pawn is not affiliated with the event or the players."))
                    .appFont(.caption2)
                    .foregroundStyle(Theatre.ivoryFaint)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button {
                replaying = true
            } label: {
                Text(L.t("today.replay", "Replay"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(emphasis: .solid))

            Button {
                carryOn(from: story.focusPly)
            } label: {
                Text(L.t("today.tryIt", "Try it yourself"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(emphasis: .ghost))

            if let shareImage {
                ShareLink(
                    item: shareImage,
                    subject: Text(verbatim: story.title),
                    message: Text(verbatim: "\(story.title) — \(story.url.absoluteString)"),
                    preview: SharePreview(story.title, image: shareImage)
                ) {
                    BrassIcon("square.and.arrow.up", size: 15)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost))
                .accessibilityLabel(L.t("today.share", "Share"))
            }
        }
        .frame(maxWidth: 560)
    }

    @ViewBuilder
    private var words: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !TodayScreen.isEnglish {
                Text(L.t("today.inEnglish", "Commentary in English").uppercased())
                    .appFont(size: 8).tracking(1.4)
                    .foregroundStyle(Theatre.ivoryFaint)
            }
            Text(verbatim: story.headline)
                .appFont(size: 19, weight: .semibold)
                .foregroundStyle(Theatre.ivory)
            Text(verbatim: story.body)
                .appFont(.subheadline)
                .foregroundStyle(Theatre.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .environment(\.locale, Locale(identifier: "en"))
    }

    private var facts: some View {
        Panel {
            fact(L.color(.white), player(story.white))
            fact(L.color(.black), player(story.black))
            fact(L.t("today.result", "Result"),
                 "\(story.resultText) · " + L.t("watch.moveCount", "%lld moves", (story.sans.count + 1) / 2))
            if let opening = story.opening.name {
                fact(L.t("theme.opening", "Opening"), [opening, story.opening.eco].compactMap { $0 }.joined(separator: " · "))
            }
            fact(L.t("today.event", "Event"),
                 [story.event.name, story.event.location].compactMap { $0 }.joined(separator: " · "))
            if let key = story.key {
                fact(L.t("today.keyMoveLabel", "Key move"), FeedStory.label(ply: key.ply, san: key.played))
                if let better = key.better {
                    fact(L.t("today.enginesChoice", "Engine’s choice"), FeedStory.label(ply: key.ply, san: better))
                }
            }
        }
    }

    private func player(_ p: FeedStory.Player) -> String {
        let name = [p.title, p.name].compactMap { $0 }.joined(separator: " ")
        return [name, p.elo.map(String.init), p.team].compactMap { $0 }.joined(separator: " · ")
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label.uppercased())
                .appFont(size: 8).tracking(1.2)
                .foregroundStyle(Theatre.ivoryFaint)
                .frame(width: 92, alignment: .leading)
            Text(verbatim: value)
                .appFont(.footnote)
                .foregroundStyle(Theatre.ivory)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Onto the free board, from the position the story is about — or from
    /// wherever the replay had got to.
    private func carryOn(from ply: Int) {
        navigator.continueOnBoard(BoardHandoff(
            title: story.title,
            start: Position(),
            moves: Array(story.sans.prefix(ply))
        ))
        dismiss()
    }

    /// The picture that goes with a shared story: the player's own board, in
    /// the dimension they play in, with the story's title on it.
    private func renderShareImage() {
        let focus = story.focus
        var board: Image?
        #if canImport(UIKit)
        if app.progress.appearance.dimension.isDimensional,
           let still = BoardSnapshot.image(of: focus.position,
                                           lastMove: focus.lastMove.map { ($0.from, $0.to) },
                                           orientation: orientation,
                                           style: app.progress.appearance.carving.style) {
            board = Image(uiImage: still)
        }
        #endif
        let card = ShareCard(story: story, position: focus.position, lastMove: focus.lastMove,
                             orientation: orientation, rendered: board)
            .environment(\.boardTheme, boardTheme)
            .environment(\.pieceSet, pieceSet)
            .environment(\.showsBoardCoordinates, false)
            .appTypeface(app.progress.appearance.typeface)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        #if canImport(UIKit)
        if let image = renderer.uiImage { shareImage = Image(uiImage: image) }
        #elseif canImport(AppKit)
        if let image = renderer.nsImage { shareImage = Image(nsImage: image) }
        #endif
    }
}

/// The picture a shared story travels as: 4:5, which is what the places people
/// share pictures to crop to, with the board filling most of it.
private struct ShareCard: View {
    let story: FeedStory
    let position: Position
    let lastMove: Move?
    let orientation: PieceColor
    /// The round board, already drawn, when the player plays in 3D.
    let rendered: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(story.occasion.uppercased())
                .appFont(size: 9).tracking(2)
                .foregroundStyle(Theatre.brass)
            Text(verbatim: story.title)
                .appFont(size: 22, weight: .semibold)
                .foregroundStyle(Theatre.ivory)
                .lineLimit(2)
            Group {
                if let rendered {
                    rendered.resizable().scaledToFill()
                } else {
                    BoardView(position: position, orientation: orientation,
                              lastMove: lastMove.map { ($0.from, $0.to) })
                }
            }
            .frame(width: 324, height: 324)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            HStack {
                if let key = story.key {
                    Text(verbatim: L.t("today.after", "After %@", FeedStory.label(ply: key.ply, san: key.played)))
                }
                Spacer()
                Text(verbatim: "Brass Pawn · brasspawn.com")
            }
            .appFont(size: 9).tracking(1)
            .foregroundStyle(Theatre.ivoryDim)
        }
        .padding(18)
        .frame(width: 360, height: 450, alignment: .topLeading)
        .background(Theatre.ink)
    }
}

import BoardScene
import ChessCore
import ChessTraining
import SwiftUI

/// Somebody else's game, on the player's chosen board, with the controls a
/// recording ought to have.
///
/// The point of watching rather than replaying in your head is being able to
/// stop: a move that looks like a blunder is worth a second look, and the way
/// to give it one is to wind back two moves and let it happen again.
struct WatchScreen: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(AppModel.self) private var app
    @Environment(Navigator.self) private var navigator

    let game: ClassicGame

    /// How far the viewer has got, so the preview can hand over from there
    /// rather than from a number chosen in advance.
    @State private var watchedPly = 0

    var body: some View {
        ReplayViewer(
            title: game.players,
            subtitle: game.occasion,
            startingPosition: Position(),
            notation: game.moves,
            // Picked up where it was left. A recording is watched the way a
            // recording is watched — in sittings — and nine hundred games is
            // far too many to remember your own place in.
            startAt: app.progress.watchMark(for: game.id)?.ply ?? 0,
            onProgress: { ply, total in
                watchedPly = ply
                app.update { $0.mark(watched: game.id, ply: ply, of: total) }
            },
            onContinue: { ply in carryOn(from: ply) },
            onDismiss: { dismiss() }
        )
        #if DEBUG
        // The preview watches for a while, then takes the game over — the whole
        // point of the feature is the crossing from one screen to the other, and
        // that only reads as anything if it happens on camera.
        .task {
            guard ScreenshotScene.requested == .demoWatch else { return }
            // About a third of the preview is the game replaying. Long enough
            // to read as watching, short enough that the crossing still lands
            // inside Apple's thirty seconds.
            try? await Task.sleep(for: .seconds(7))
            carryOn(from: watchedPly)
        }
        #endif
    }

    private func carryOn(from ply: Int) {
        navigator.continueOnBoard(BoardHandoff(
            title: game.players,
            start: Position(),
            moves: Array(game.moves.split(separator: " ").map(String.init).prefix(ply))
        ))
        dismiss()
    }
}

/// The actual Watch player, shared by full games and short tactic solutions.
/// Supplying the initial position is what lets a three-move combination use
/// exactly the same board and transport as a complete classical game. Unlike
/// the main menu's permanent title scene, this viewer honours the 2D/3D
/// appearance preference.
struct ReplayViewer: View {
    @Environment(AppModel.self) private var app

    let title: String
    let subtitle: String
    let startingPosition: Position
    let notation: String
    /// Where to open. Nought for anything that has no memory of being watched.
    var startAt: Int = 0
    /// Called as the viewer moves through the game, with the half-move reached
    /// and the number in the whole game.
    var onProgress: ((Int, Int) -> Void)?
    /// Offered when the game can be taken over. Handed the half-move reached,
    /// so the board picks it up exactly where the viewer is standing.
    var onContinue: ((Int) -> Void)?
    let onDismiss: () -> Void

    @State private var player: GamePlayer?
    @State private var index = 0
    @State private var isPlaying = false
    @State private var scrubbing = false
    @State private var playbackSpeed = 1.0

    private var plies: [Ply] { player?.plies ?? [] }

    /// Take the game over from where you are standing.
    ///
    /// Deliberately not a takeback: the game is loaded onto the free board from
    /// this position with the moves that led to it, and carries on as one line.
    /// A takeback that could be undone would need a tree of variations, and a
    /// recording is not the place to grow one.
    @ViewBuilder
    private var continueRow: some View {
        if let onContinue {
            Button {
                onContinue(index)
            } label: {
                Label {
                    Text(L.t("watch.continueHere", "Play on from here"))
                } icon: {
                    BrassIcon("arrow.turn.down.right", size: 15)
                }
                .appFont(.footnote)
                .foregroundStyle(Theatre.brass)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            heading
            replayBoard
            moves
            continueRow
            transport
        }
        .background(Theatre.ink.ignoresSafeArea())
        .onAppear(perform: build)
        .onChange(of: app.progress.appearance.showsCoordinates) { _, showing in
            player?.stage.setCoordinates(showing)
        }
        .onDisappear { player?.pause() }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            // BoardSceneView owns the display link while the board is 3D. A
            // flat board has no renderer loop, so advance the same player here
            // to keep autoplay and playback speed identical in both modes.
            guard !app.progress.appearance.dimension.isDimensional else { return }
            player?.advance(delta: 0.05)
        }
    }

    @ViewBuilder
    private var replayBoard: some View {
        if let player {
            #if canImport(UIKit)
            if app.progress.appearance.dimension.isDimensional {
                BoardSceneView(sequence: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                flatBoard(player)
            }
            #else
            flatBoard(player)
            #endif
        }
    }

    private func flatBoard(_ player: GamePlayer) -> some View {
        GameBoard(
            position: player.currentPosition,
            lastMove: player.lastMove
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heading: some View {
        BrassNavigationHeader(
            title: title,
            subtitle: subtitle
        ) {
            onDismiss()
        }
    }

    /// The score, scrolling, with the move you are looking at lit — and every
    /// move a way of getting there.
    private var moves: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(plies.enumerated()), id: \.offset) { offset, ply in
                        let current = offset == index - 1
                        Button {
                            player?.seek(to: offset + 1)
                        } label: {
                            HStack(spacing: 3) {
                                if let prefix = moveNumberPrefix(for: offset) {
                                    Text(verbatim: prefix)
                                        .appFont(size: 9)
                                        .foregroundStyle(Theatre.ivoryFaint)
                                }
                                Text(ply.san)
                                    .appFont(size: 11, weight: current ? .semibold : .regular)
                                    .foregroundStyle(current ? Theatre.brassHot : Theatre.ivoryDim)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .foregroundStyle(current ? Theatre.brassHot : Theatre.ivoryDim)
                            .background {
                                if current {
                                    BrassPlateShape(cut: 6).fill(Theatre.brassGlow)
                                }
                            }
                            .overlay {
                                if current {
                                    BrassPlateShape(cut: 6)
                                        .strokeBorder(Theatre.brass.opacity(0.65), lineWidth: 0.7)
                                }
                            }
                        }
                        .buttonStyle(BrassPressStyle())
                        .id(offset)
                    }
                }
                .padding(.horizontal, 14)
            }
            .frame(height: 34)
            .onChange(of: index) { _, value in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(max(0, value - 1), anchor: .center)
                }
                onProgress?(value, plies.count)
            }
        }
    }

    /// Full games start with White on move one, but a tactic can start with
    /// Black on move 37. Preserve the FEN's real numbering in the move strip.
    private func moveNumberPrefix(for offset: Int) -> String? {
        let startsWithBlack = startingPosition.sideToMove == .black
        let absoluteOffset = offset + (startsWithBlack ? 1 : 0)
        let moveNumber = startingPosition.fullmoveNumber + absoluteOffset / 2
        if absoluteOffset.isMultiple(of: 2) { return "\(moveNumber)." }
        return offset == 0 ? "\(moveNumber)..." : nil
    }

    private var transport: some View {
        ReplayTransport(
            position: index,
            count: plies.count,
            isPlaying: isPlaying,
            speedLabel: "\(playbackSpeed.formatted())×",
            onSeek: { player?.seek(to: $0) },
            onToggle: { player?.toggle() },
            onCycleSpeed: cycleSpeed,
            onEditingChanged: { editing in
                scrubbing = editing
                if editing { player?.pause() }
            }
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            // The player stops itself at the end of the game, and the button
            // has to notice.
            if let player, isPlaying != player.isPlaying { isPlaying = player.isPlaying }
        }
    }

    private func cycleSpeed() {
        let rates = [0.5, 1.0, 1.5, 2.0, 3.0]
        let index = rates.firstIndex(of: playbackSpeed) ?? 1
        let next = rates[(index + 1) % rates.count]
        withAnimation(.easeOut(duration: 0.16)) {
            playbackSpeed = next
        }
        player?.speed = next
    }

    private func build() {
        guard player == nil else { return }
        let made = GamePlayer(
            quality: SceneQuality.forThisDevice,
            style: app.progress.appearance.carving.style
        )
        made.speed = playbackSpeed
        made.onChange = { value in
            index = value
            isPlaying = made.isPlaying
        }
        made.load(position: startingPosition, notation: notation)
        made.stage.setCoordinates(app.progress.appearance.showsCoordinates)
        // Not past the end: a game watched to the last move opens at the last
        // move, which is a still picture. Better to hand it back at the start.
        if startAt > 0, startAt < made.plies.count {
            made.seek(to: startAt)
            index = startAt
        }
        player = made
        // Straight into it: both a watched game and a revealed combination
        // are opened in order to see the moves happen.
        made.play()
        isPlaying = true
    }
}

/// The playback control shared by watched classics and Guess the Elo. Keeping
/// one transport means the same icons, slider and speed control behave the
/// same way everywhere a recorded game is replayed.
struct ReplayTransport: View {
    private let controlHorizontalPadding: CGFloat = 6

    let position: Int
    let count: Int
    let isPlaying: Bool
    let speedLabel: String
    var usesPlainLabels = false
    var showsPositionSlider = true
    var showsEndButtons = true
    var primaryAction: ActionItem? = nil
    let onSeek: (Int) -> Void
    let onToggle: () -> Void
    let onCycleSpeed: () -> Void
    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 10) {
            if showsPositionSlider {
                BrassSlider(
                    value: Binding(
                        get: { Double(position) },
                        set: { onSeek(Int($0.rounded())) }
                    ),
                    in: 0...Double(max(count, 1)),
                    step: 1,
                    onEditingChanged: onEditingChanged
                )
            }

            HStack(spacing: 6) {
                if showsEndButtons {
                    button("backward.end.fill") { onSeek(0) }
                }
                button("backward.fill") { onSeek(max(0, position - 1)) }
                button(isPlaying ? "pause.fill" : "play.fill", wide: true, action: onToggle)
                button("forward.fill") { onSeek(min(count, position + 1)) }
                if showsEndButtons {
                    button("forward.end.fill") { onSeek(count) }
                }
                speed
                if let primaryAction {
                    primaryButton(primaryAction)
                }
            }
        }
    }

    private var speed: some View {
        Button(action: onCycleSpeed) {
            Text(speedLabel)
                .appFont(size: usesPlainLabels ? 13 : 11, weight: .medium)
                .foregroundStyle(Theatre.ivoryDim)
                .contentTransition(.numericText())
                .padding(.horizontal, controlHorizontalPadding)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    BrassPlateShape(cut: 8).fill(Theatre.ink3)
                }
                .overlay {
                    BrassPlateShape(cut: 8)
                        .strokeBorder(Theatre.brassDeep.opacity(0.5), lineWidth: 0.75)
                }
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(L.t("guess.speed", "Speed"))
        .accessibilityValue(speedLabel)
    }

    private func primaryButton(_ item: ActionItem) -> some View {
        Button(action: item.action) {
            HStack(spacing: 4) {
                BrassIcon(item.systemImage, size: 16)
                Text(item.title)
                    .appFont(size: usesPlainLabels ? 10 : 9, weight: .semibold)
                    .tracking(usesPlainLabels ? 0 : 0.8)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Theatre.brassHot)
            .padding(.horizontal, controlHorizontalPadding)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background {
                BrassPlateShape(cut: 8).fill(LinearGradient(
                    colors: [Theatre.ink4, Theatre.ink2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
            .overlay {
                BrassPlateShape(cut: 8)
                    .strokeBorder(Theatre.brassHot.opacity(0.8), lineWidth: 0.75)
            }
        }
        .buttonStyle(BrassPressStyle())
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1 : 0.3)
    }

    private func button(
        _ symbol: String,
        wide: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            BrassIcon(symbol, size: wide ? 19 : 16)
                .foregroundStyle(wide ? Theatre.brassHot : Theatre.ivory)
                .padding(.horizontal, controlHorizontalPadding)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    BrassPlateShape(cut: 8).fill(LinearGradient(
                        colors: wide ? [Theatre.ink4, Theatre.ink2] : [Theatre.ink3, Theatre.ink2],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
                .overlay {
                    BrassPlateShape(cut: 8)
                        .strokeBorder(
                            wide ? Theatre.brassHot.opacity(0.8) : Theatre.brassDeep.opacity(0.5),
                            lineWidth: 0.75
                        )
                }
        }
        .buttonStyle(BrassPressStyle())
    }
}

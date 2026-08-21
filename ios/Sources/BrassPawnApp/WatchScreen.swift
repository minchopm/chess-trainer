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

    let game: ClassicGame

    var body: some View {
        ReplayViewer(
            title: game.players,
            subtitle: game.occasion,
            startingPosition: Position(),
            notation: game.moves,
            onDismiss: { dismiss() }
        )
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
    let onDismiss: () -> Void

    @State private var player: GamePlayer?
    @State private var index = 0
    @State private var isPlaying = false
    @State private var scrubbing = false
    @State private var playbackSpeed = 1.0

    private var plies: [Ply] { player?.plies ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            heading
            replayBoard
            moves
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
            style: app.progress.appearance.carving == .banded ? .banded : .plain
        )
        made.speed = playbackSpeed
        made.onChange = { value in
            index = value
            isPlaying = made.isPlaying
        }
        made.load(position: startingPosition, notation: notation)
        made.stage.setCoordinates(app.progress.appearance.showsCoordinates)
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
                    .minimumScaleFactor(0.8)
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

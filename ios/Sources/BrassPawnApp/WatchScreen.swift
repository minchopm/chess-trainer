import BoardScene
import ChessTraining
import SwiftUI

/// Somebody else's game, on the round board, with the controls a recording
/// ought to have.
///
/// The point of watching rather than replaying in your head is being able to
/// stop: a move that looks like a blunder is worth a second look, and the way
/// to give it one is to wind back two moves and let it happen again.
struct WatchScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    let game: ClassicGame

    @State private var player: GamePlayer?
    @State private var index = 0
    @State private var isPlaying = false
    @State private var scrubbing = false
    @State private var playbackSpeed = 1.0

    private var plies: [Ply] { player?.plies ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            heading
            #if canImport(UIKit)
            if let player {
                BoardSceneView(sequence: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            #endif
            moves
            transport
        }
        .background(Theatre.ink.ignoresSafeArea())
        .onAppear(perform: build)
        .onDisappear { player?.pause() }
    }

    private var heading: some View {
        BrassNavigationHeader(
            title: game.players,
            subtitle: game.occasion
        ) {
            dismiss()
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
                                if offset % 2 == 0 {
                                    Text(verbatim: "\(offset / 2 + 1).")
                                        .font(Face.mono(9))
                                        .foregroundStyle(Theatre.ivoryFaint)
                                }
                                Text(ply.san)
                                    .font(Face.mono(11, weight: current ? .semibold : .regular))
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

    private var transport: some View {
        VStack(spacing: 10) {
            BrassSlider(
                value: Binding(
                    get: { Double(index) },
                    set: { player?.seek(to: Int($0.rounded())) }
                ),
                in: 0...Double(max(plies.count, 1)),
                step: 1,
                onEditingChanged: { editing in
                    scrubbing = editing
                    if editing { player?.pause() }
                }
            )

            HStack(spacing: 8) {
                button("backward.end.fill") { player?.seek(to: 0) }
                button("backward.fill") { player?.step(-1) }
                button(isPlaying ? "pause.fill" : "play.fill", wide: true) { player?.toggle() }
                button("forward.fill") { player?.step(1) }
                button("forward.end.fill") { player?.seek(to: plies.count) }
                speed
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            // The player stops itself at the end of the game, and the button
            // has to notice.
            if let player, isPlaying != player.isPlaying { isPlaying = player.isPlaying }
        }
    }

    private var speed: some View {
        Button(action: cycleSpeed) {
            Text(verbatim: "\(playbackSpeed.formatted())×")
                .font(Face.mono(11, weight: .medium))
                .foregroundStyle(Theatre.ivoryDim)
                .contentTransition(.numericText())
                .frame(width: 46, height: 38)
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
        .accessibilityValue("\(playbackSpeed.formatted())×")
    }

    private func button(_ symbol: String, wide: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: wide ? 15 : 12, weight: .semibold))
                .foregroundStyle(wide ? Theatre.brassHot : Theatre.ivory)
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
                        .strokeBorder(wide ? Theatre.brassHot.opacity(0.8) : Theatre.brassDeep.opacity(0.5),
                                      lineWidth: 0.75)
                }
        }
        .buttonStyle(BrassPressStyle())
    }

    private func cycleSpeed() {
        let rates = [0.5, 1.0, 1.5, 2.0, 3.0]
        let index = rates.firstIndex(of: playbackSpeed) ?? 1
        let next = rates[(index + 1) % rates.count]
        withAnimation(.easeOut(duration: 0.16)) {
            playbackSpeed = next
        }
        player?.speed = next
        SoundBoard.shared.play(.move)
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
        made.load(notation: game.moves)
        player = made
        // Straight into it: nobody opens a recording in order to look at the
        // starting position.
        made.play()
        isPlaying = true
    }
}

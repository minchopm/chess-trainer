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
        ZStack(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theatre.ivoryDim)
                    .frame(width: 34, height: 34)
                    .background(Theatre.ink3, in: Circle())
                    .overlay(Circle().strokeBorder(Theatre.rule, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .zIndex(1)

            title
        }
        .padding(.top, 10)
        .padding(.horizontal, 16)
    }

    private var title: some View {
        VStack(spacing: 3) {
            Text(game.players)
                .font(Face.display(20))
                .foregroundStyle(Theatre.ivory)
                .multilineTextAlignment(.center)
            Text(game.occasion)
                .font(Face.mono(9)).tracking(1.6)
                .foregroundStyle(Theatre.ivoryFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 44)
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
                                    .foregroundStyle(current ? Theatre.ink : Theatre.ivoryDim)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(current ? Theatre.brass : .clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
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
            Slider(
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
            .tint(Theatre.brass)

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
        Menu {
            ForEach([0.5, 1.0, 1.5, 2.0, 3.0], id: \.self) { rate in
                Button {
                    player?.speed = rate
                } label: {
                    Text(verbatim: rate == 1 ? "1×" : "\(rate.formatted())×")
                }
            }
        } label: {
            Text(verbatim: "\((player?.speed ?? 1).formatted())×")
                .font(Face.mono(11, weight: .medium))
                .foregroundStyle(Theatre.ivoryDim)
                .frame(width: 42, height: 38)
                .background(Theatre.ink3, in: Capsule())
                .overlay(Capsule().strokeBorder(Theatre.rule, lineWidth: 0.75))
        }
    }

    private func button(_ symbol: String, wide: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: wide ? 15 : 12, weight: .semibold))
                .foregroundStyle(wide ? Theatre.ink : Theatre.ivory)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(wide ? Theatre.brass : Theatre.ink3, in: Capsule())
                .overlay(Capsule().strokeBorder(wide ? .clear : Theatre.rule, lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    private func build() {
        guard player == nil else { return }
        let made = GamePlayer(
            quality: SceneQuality.forThisDevice,
            style: app.progress.appearance.carving == .banded ? .banded : .plain
        )
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

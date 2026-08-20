import BoardScene
import ChessTraining
import SwiftUI

/// The first screen: the board, playing to itself, with the way in over it.
///
/// The same three games the site plays, on the same set, in the same room. It
/// is the one place in the app where nothing is being asked of the player, so
/// it is the one place that can afford to be only a picture.
struct MenuScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @Environment(Navigator.self) private var navigator
    let onChoose: (RootView.Tab) -> Void

    /// Built once, with whichever set the player has chosen. The set is part
    /// of the geometry, so choosing another one builds another board — which is
    /// what the `id` on this screen is for.
    @State private var sequence: TitleSequence
    @State private var caption: ShowGame?

    init(carving: Carving, onChoose: @escaping (RootView.Tab) -> Void) {
        self.onChoose = onChoose
        _sequence = State(initialValue: TitleSequence(
            quality: SceneQuality.forThisDevice,
            style: carving == .banded ? .banded : .plain
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            // Wide enough to put the menu beside the board rather than on top
            // of it. That is an iPad in landscape, and it is the shape this
            // screen is worth looking at in: the board gets the room and the
            // way in stops covering the game.
            let wide = geometry.size.width > geometry.size.height * 1.15
            let column: CGFloat = wide ? min(400, geometry.size.width * 0.34) : 0
            let apron: CGFloat = wide ? 0 : 215

            ZStack {
                // The scene is drawn larger than the screen and pushed away
                // from the controls, so the board lands in the clear part of
                // the frame. Moving the picture is cheaper and steadier than
                // asking the camera to compose around a rectangle it cannot
                // see, and the room is the same colour as the page, so the
                // overhang has no edge.
                #if canImport(UIKit)
                BoardSceneView(sequence: sequence)
                    .frame(
                        width: geometry.size.width + column,
                        height: geometry.size.height + apron
                    )
                    .offset(x: column / 2, y: -apron / 2)
                    // Pinned back to the screen afterwards. Without this the
                    // oversized scene is what the stack measures, everything
                    // else is laid out inside a frame taller than the display,
                    // and the title ends up above the top of it.
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)
                #endif

                if wide {
                    HStack(spacing: 0) {
                        VStack(spacing: 18) {
                            title
                            choices(compact: false)
                            if let caption { self.caption(caption) }
                        }
                        .frame(width: column)
                        .padding(.leading, 26)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: 0) {
                        title
                        Spacer(minLength: 0)
                        choices(compact: true)
                        if let caption { self.caption(caption) }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(Theatre.ink)
        .onAppear {
            caption = sequence.game
            sequence.onGame = { game in
                withAnimation(.easeInOut(duration: 0.5)) { caption = game }
            }
        }
    }

    private var title: some View {
        VStack(spacing: 6) {
            Text(L.t("menu.title", "Brass Pawn"))
                .font(Face.display(44))
                .foregroundStyle(Theatre.ivory)
                .shadow(color: Theatre.ink.opacity(0.9), radius: 18, y: 4)
            Slug(text: L.t("menu.slug", "Play · Train · Watch"), trailingRule: false)
        }
        .frame(maxWidth: .infinity)
    }

    /// The way in.
    ///
    /// Compact on a phone, where five stacked rows of buttons take more than
    /// half the screen and the board ends up behind them — which defeats a
    /// first screen whose whole job is to be watched. Beside the board there is
    /// room to stack them.
    @ViewBuilder
    private func choices(compact: Bool) -> some View {
        if compact {
            VStack(spacing: 9) {
                entry(.play, L.t("progress.play", "Play"), "person.2", solid: true)
                HStack(spacing: 7) {
                    small(.play, L.t("progress.watch", "Watch"), "play.rectangle", wants: .watch)
                    small(.tactics, L.t("progress.tactics", "Tactics"), "target")
                    small(.positional, L.t("progress.positional", "Positional"), "square.grid.3x3.middle.filled")
                    small(.endgames, L.t("progress.endgames", "Endgames"), "flag.checkered")
                    small(.progress, L.t("progress.progress", "Progress"), "chart.line.uptrend.xyaxis")
                }
            }
            .frame(maxWidth: 460)
        } else {
            VStack(spacing: 9) {
                entry(.play, L.t("progress.play", "Play"), "person.2", solid: true)
                HStack(spacing: 9) {
                    entry(.play, L.t("progress.watch", "Watch"), "play.rectangle", wants: .watch)
                    entry(.tactics, L.t("progress.tactics", "Tactics"), "target")
                }
                HStack(spacing: 9) {
                    entry(.positional, L.t("progress.positional", "Positional"), "square.grid.3x3.middle.filled")
                    entry(.endgames, L.t("progress.endgames", "Endgames"), "flag.checkered")
                }
                entry(.progress, L.t("progress.progress", "Progress"), "chart.line.uptrend.xyaxis")
            }
        }
    }

    /// An icon over a very small label — a whole row of them fits where two
    /// full-width buttons would.
    private func small(_ tab: RootView.Tab, _ title: String, _ symbol: String,
                       wants: PlayTab.Mode? = nil) -> some View {
        Button {
            SoundBoard.shared.play(.move)
            if let wants { navigator.playMode = wants }
            onChoose(tab)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 15, weight: .light))
                Text(title.uppercased())
                    .font(Face.mono(7)).tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Theatre.ivoryDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Theatre.ink3.opacity(0.85), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Theatre.rule, lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    private func entry(_ tab: RootView.Tab, _ title: String, _ symbol: String,
                       solid: Bool = false, wants: PlayTab.Mode? = nil) -> some View {
        Button {
            SoundBoard.shared.play(.move)
            if let wants { navigator.playMode = wants }
            onChoose(tab)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                Text(title.uppercased())
                    .font(Face.mono(11, weight: .medium))
                    .tracking(2.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
        }
        .buttonStyle(PillButtonStyle(emphasis: solid ? .solid : .ghost))
    }

    private func caption(_ game: ShowGame) -> some View {
        VStack(spacing: 3) {
            Text(game.caption)
                .font(Face.display(17))
                .foregroundStyle(Theatre.ivoryDim)
            Text(game.occasion)
                .font(Face.mono(9))
                .tracking(1.6)
                .foregroundStyle(Theatre.ivoryFaint)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 14)
        .transition(.opacity)
        .id(game.id)
    }
}

extension SceneQuality {
    /// Two settings, chosen once. The distinction that matters is not the model
    /// of phone but whether the device has the memory bandwidth for a
    /// full-resolution shadow map and a bloom pass over the whole screen.
    static var forThisDevice: SceneQuality {
        #if targetEnvironment(simulator)
        // The simulator renders SceneKit on the Mac's GPU through a translation
        // layer, where the shadow map is the expensive part.
        return .low
        #else
        return ProcessInfo.processInfo.processorCount >= 6 ? .high : .low
        #endif
    }
}

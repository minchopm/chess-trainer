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

    @State private var sequence = TitleSequence(quality: SceneQuality.forThisDevice)
    @State private var caption: ShowGame?

    var body: some View {
        ZStack {
            // The scene is iOS-only: the package still builds for macOS so
            // the rules and the geometry can be tested from the command line,
            // and there is no Mac app to host a view in.
            #if canImport(UIKit)
            BoardSceneView(sequence: sequence)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            #endif

            // The room is lit from the top left and the board sits low in the
            // frame; the type needs its own ground or it competes with the
            // brightest part of the picture.
            LinearGradient(
                colors: [Theatre.ink.opacity(0.92), Theatre.ink.opacity(0.15), .clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                title
                Spacer(minLength: 0)
                choices
                if let caption { self.caption(caption) }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 14)
        }
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

    private var choices: some View {
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
        .frame(maxWidth: 460)
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

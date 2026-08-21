import BoardScene
import ChessCore
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
    @State private var showsPurchases = false
    @State private var showsSettings = false

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
                            if let caption { self.caption(caption) }
                            choices(compact: false)
                        }
                        .frame(width: column)
                        .padding(.leading, 26)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: 0) {
                        title
                        Spacer(minLength: 0)
                        if let caption { self.caption(caption) }
                        choices(compact: true)
                    }
                    .padding(.horizontal, 22)
                    // Leave a clear row for the two menu actions above the
                    // title on a phone.
                    .padding(.top, 40)
                    .padding(.bottom, 14)
                }
            }
            .overlay(alignment: .top) {
                menuActions
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
        .fullScreenCover(isPresented: $showsPurchases) { PaywallView() }
        .fullScreenCover(isPresented: $showsSettings) { SettingsScreen() }
    }

    /// Purchases and preferences sit together in the top-right corner, with
    /// settings at the outside edge where it is quickest to find.
    private var menuActions: some View {
        HStack(spacing: 0) {
            menuAction(
                symbol: "creditcard",
                label: L.t("store.title", "Brass Pawn Pro")
            ) {
                showsPurchases = true
            }

            Rectangle()
                .fill(Theatre.brassDeep.opacity(0.65))
                .frame(width: 1, height: 27)

            menuAction(
                symbol: "gearshape",
                label: L.t("settings.settings", "Settings")
            ) {
                showsSettings = true
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background {
            MenuChamferedShape(cut: 11)
                .fill(Theatre.ink3.opacity(0.94))
        }
        .overlay {
            MenuChamferedShape(cut: 11)
                .strokeBorder(Theatre.brassDeep.opacity(0.75), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.45), radius: 14, y: 5)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func menuAction(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theatre.brassHot.opacity(0.9))
                .frame(width: 46, height: 42)
        }
        .buttonStyle(MenuPressStyle())
        .accessibilityLabel(label)
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
        VStack(spacing: compact ? 9 : 12) {
            playEntry
            HStack(spacing: -1) {
                small(.play, L.t("progress.watch", "Watch"), "play.rectangle", wants: .watch)
                small(.tactics, L.t("progress.tactics", "Tactics"), "target")
                small(.positional, L.t("progress.positional", "Positional"), "square.grid.3x3.middle.filled")
                small(.endgames, L.t("progress.endgames", "Endgames"), "flag.checkered")
                small(.progress, L.t("progress.progress", "Progress"), "chart.line.uptrend.xyaxis")
            }
        }
        .frame(maxWidth: 460)
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
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .light))
                Text(title.uppercased())
                    .font(Face.mono(7)).tracking(1.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .foregroundStyle(Theatre.ivoryDim)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background {
                MenuChamferedShape(cut: 9)
                    .fill(LinearGradient(
                        colors: [Theatre.ink4.opacity(0.96), Theatre.ink2.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .overlay {
                MenuChamferedShape(cut: 9)
                    .strokeBorder(Theatre.brassDeep.opacity(0.48), lineWidth: 0.75)
            }
        }
        .buttonStyle(MenuPressStyle())
    }

    private var playEntry: some View {
        Button {
            SoundBoard.shared.play(.move)
            onChoose(.play)
        } label: {
            ZStack {
                MenuChamferedShape(cut: 12)
                    .fill(LinearGradient(
                        colors: [Theatre.ink3.opacity(0.97), Theatre.ink2.opacity(0.93)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .padding(.vertical, 7)

                HStack(spacing: 0) {
                    playMedallion

                    Text(L.t("progress.play", "Play").uppercased())
                        .font(Face.display(29))
                        .tracking(4.2)
                        .foregroundStyle(Theatre.ivory)
                        .frame(maxWidth: .infinity)

                    Color.clear.frame(width: 78)
                }
            }
            .frame(height: 76)
            .overlay {
                MenuChamferedShape(cut: 12)
                    .strokeBorder(Theatre.brassDeep.opacity(0.7), lineWidth: 0.8)
                    .padding(.vertical, 7)
            }
        }
        .buttonStyle(MenuPressStyle())
        .accessibilityLabel(L.t("progress.play", "Play"))
    }

    private var playMedallion: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Theatre.brassDeep.opacity(0.4), Theatre.ink2],
                    center: .center,
                    startRadius: 2,
                    endRadius: 36
                ))
            Circle().strokeBorder(Theatre.brassHot.opacity(0.9), lineWidth: 1.5)
            Circle()
                .strokeBorder(Theatre.brassDeep.opacity(0.9), lineWidth: 3)
                .padding(5)
            PieceView(piece: Piece(.white, .knight), size: 48)
        }
        .frame(width: 70, height: 70)
        .padding(.leading, 8)
        .shadow(color: .black.opacity(0.75), radius: 8, y: 4)
        .shadow(color: Theatre.brassGlow, radius: 10)
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
        .padding(.bottom, 14)
        .transition(.opacity)
        .id(game.id)
    }
}

/// The clipped metal plate shared by the menu controls.
private struct MenuChamferedShape: InsettableShape {
    var cut: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let corner = min(cut, min(bounds.width, bounds.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: bounds.minX + corner, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX - corner, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY + corner))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - corner))
        path.addLine(to: CGPoint(x: bounds.maxX - corner, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX + corner, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY - corner))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + corner))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> MenuChamferedShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct MenuPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
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

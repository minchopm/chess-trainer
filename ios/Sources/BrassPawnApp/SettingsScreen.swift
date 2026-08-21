import ChessCore
import ChessTraining
import SwiftUI

/// A slim row at the top of every training screen. The middle content is
/// centred against the whole screen, not against the space left by the back
/// button, so titles and mode pickers do not drift to the right.
struct TopBar<Content: View>: View {
    @Environment(ActivityGuard.self) private var activity
    @Environment(Navigator.self) private var navigator
    /// Set only by an online game. The row is empty during play anyway, and a
    /// clock is the one thing that has to be readable without looking away
    /// from the board.
    var clocks: ClockStrip?
    @ViewBuilder var content: Content

    var body: some View {
        // Whatever the screen puts here — a mode picker, usually — is a way
        // out of the game as much as the tab bar is, so it goes away for
        // the same reason and comes back at the same moment.
        Group {
            if activity.isActive {
                if let clocks { clocks } else { Color.clear }
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        // Empty training headers use Spacer/Color.clear as their centre
        // content. Without an explicit height those flexible views consume
        // the remaining screen and push the board away.
        // Shorter than it was, and the way out no longer sits in it.
        .frame(height: 30)
        .padding(.horizontal, 54)
        .overlay(alignment: .leading) {
            // Lifted into the strip above, which the app leaves empty — it
            // hides the status bar, so the room the clock would have taken was
            // going spare. A row of its own for one round button is a row the
            // list could have had.
            BrassBackButton {
                if activity.isActive { activity.requestExit() } else { navigator.goToMenu() }
            }
            .offset(y: -26)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
}

struct SettingsScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var volumeBeforeMute = 0.7

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("settings.settings", "Settings")) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section(L.t("settings.sounds", "Move sounds")) { sound }
                    section(L.t("settings.dimension", "Board")) { DimensionChoice() }
                    if !app.progress.appearance.dimension.isDimensional {
                        section(L.t("settings.pieces", "Pieces")) { PieceSetGallery() }
                        section(L.t("settings.squares", "Squares")) { BoardGallery() }
                        section(L.t("settings.lightSide", "Light side")) { LightToneGallery() }
                    }
                    section(L.t("settings.coordinates", "Coordinates")) { CoordinatesSwitch() }
                    section(L.t("settings.font", "Application font")) { TypefaceChoice() }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .background(Theatre.ink.ignoresSafeArea())
        }
    }

    private func section<Content: View>(
        _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Slug(text: title)
            content()
        }
    }

    private var sound: some View {
        let soundIsOn = app.progress.appearance.soundsOn
            && app.progress.appearance.volume > 0

        return Panel {
            Text(L.t("settings.soundsOn", "Play sounds"))
                .appFont(.subheadline)
                .foregroundStyle(Theatre.ivory)

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                        if soundIsOn {
                            volumeBeforeMute = app.progress.appearance.volume
                            app.update {
                                $0.appearance.soundsOn = false
                                $0.appearance.volume = 0
                            }
                        } else {
                            app.update {
                                $0.appearance.soundsOn = true
                                $0.appearance.volume = max(volumeBeforeMute, 0.1)
                            }
                        }
                    }
                } label: {
                    BrassIcon(soundIsOn
                              ? "speaker.wave.2.fill"
                              : "speaker.slash.fill", size: 22)
                        .opacity(soundIsOn ? 1 : 0.55)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(soundIsOn
                                      ? Theatre.ink4
                                      : Theatre.ink2)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(soundIsOn
                                              ? Theatre.brassHot
                                              : Theatre.brassDeep.opacity(0.65),
                                              lineWidth: 1)
                        }
                        .shadow(color: soundIsOn
                                ? Theatre.brassGlow
                                : .clear,
                                radius: 7)
                        .contentShape(Circle())
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(BrassPressStyle())
                .accessibilityLabel(L.t("settings.soundsOn", "Play sounds"))
                .accessibilityValue(soundIsOn ? "On" : "Off")

                BrassSlider(
                    value: Binding(
                        get: { app.progress.appearance.volume },
                        set: { level in
                            if level > 0 { volumeBeforeMute = level }
                            app.update {
                                $0.appearance.volume = level
                                $0.appearance.soundsOn = level > 0
                            }
                        }
                    ),
                    in: 0...1
                ) { editing in
                    // A sample on release, so the slider can be judged by ear
                    // rather than by the number next to it.
                    if !editing { SoundBoard.shared.play(.move) }
                }
            }
        }
        .onAppear {
            let currentVolume = app.progress.appearance.volume
            if app.progress.appearance.soundsOn, currentVolume > 0 {
                volumeBeforeMute = currentVolume
            } else if currentVolume > 0 {
                volumeBeforeMute = currentVolume
                app.update { $0.appearance.volume = 0 }
            }
        }
    }

}

/// The family is applied live at RootView, so choosing from the compact menu
/// immediately redraws this screen and every destination with the same face.
private struct TypefaceChoice: View {
    @Environment(AppModel.self) private var app
    @State private var isExpanded = false

    /// The picker is the last control in Settings. Expanding it in the normal
    /// layout direction put the choices below the visible scroll area, which
    /// made the tap appear to do nothing. Keep the menu floating above its
    /// trigger instead, like a compact custom pop-up.
    private let menuGap: CGFloat = 8
    private let menuHeight: CGFloat = 135

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Text(app.progress.appearance.typeface.name)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)

                Spacer(minLength: 8)

                BrassIcon("chevron.down", size: 16)
                    .foregroundStyle(Theatre.brassHot)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background {
                BrassPlateShape(cut: 10)
                    .fill(isExpanded ? Theatre.ink4 : Theatre.ink3)
            }
            .overlay {
                BrassPlateShape(cut: 10)
                    .strokeBorder(
                        isExpanded ? Theatre.brassHot : Theatre.brassDeep.opacity(0.62),
                        lineWidth: isExpanded ? 1.2 : 0.8
                    )
            }
            .shadow(color: isExpanded ? Theatre.brassGlow : .clear, radius: 8)
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(L.t("settings.font", "Application font"))
        .accessibilityValue(app.progress.appearance.typeface.name)
        .accessibilityHint(isExpanded ? "Close choices" : "Show choices")
        .overlay(alignment: .top) {
            if isExpanded {
                optionsMenu
                    .frame(height: menuHeight)
                    .offset(y: -(menuHeight + menuGap))
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.96, anchor: .bottom))
                    )
            }
        }
        .zIndex(isExpanded ? 10 : 0)
    }

    private var optionsMenu: some View {
        VStack(spacing: 0) {
            ForEach(AppTypeface.allCases) { typeface in
                option(typeface)

                if typeface != AppTypeface.allCases.last {
                    Rectangle()
                        .fill(Theatre.brassDeep.opacity(0.35))
                        .frame(height: 0.5)
                        .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 4)
        .background {
            ZStack {
                // Mask the section title underneath the floating menu,
                // including behind its clipped decorative corners.
                Theatre.ink
                BrassPlateShape(cut: 10)
                    .fill(Theatre.ink2)
            }
        }
        .overlay {
            BrassPlateShape(cut: 10)
                .strokeBorder(Theatre.brassHot.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: Theatre.shadow.opacity(0.72), radius: 18, y: 8)
    }

    private func option(_ typeface: AppTypeface) -> some View {
        let chosen = app.progress.appearance.typeface == typeface

        return Button {
            app.update { $0.appearance.typeface = typeface }
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                isExpanded = false
            }
        } label: {
            Text(typeface.name)
                // Each name is also its own preview. This is intentionally the
                // one place where rows do not inherit the active app family.
                .font(
                    AppTypography.font(
                        for: typeface,
                        style: .subheadline,
                        weight: chosen ? .semibold : .regular
                    )
                )
                .foregroundStyle(chosen ? Theatre.brassHot : Theatre.ivoryDim)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}

/// The sets, shown as themselves on a real square. Nobody picks "Ivory &
/// sapphire" from a word.
private struct PieceSetGallery: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Keep the choices readable instead of letting a wide screen squeeze all
    /// five sets into one long, shallow strip. Compact windows get two cards
    /// per row; iPad-sized windows get three.
    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(
            repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 10),
            count: count
        )
    }

    private var previewPieceSize: CGFloat {
        horizontalSizeClass == .regular ? 42 : 30
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(PieceSet.allCases) { set in
                let chosen = app.progress.appearance.pieces == set
                Button {
                    app.update { $0.appearance.pieces = set }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            ForEach([PieceKind.king, .knight], id: \.rawValue) { kind in
                                PieceView(piece: Piece(.white, kind), size: previewPieceSize)
                                    .frame(maxWidth: .infinity)
                            }
                            ForEach([PieceKind.knight, .king], id: \.rawValue) { kind in
                                PieceView(piece: Piece(.black, kind), size: previewPieceSize)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .environment(\.pieceSet, set)
                        .frame(maxWidth: .infinity)
                        // Four preview files are four squares, on every width.
                        .aspectRatio(4, contentMode: .fit)
                        .background {
                            previewBoard.clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text(set.name)
                            .appFont(size: 9, weight: .medium)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity)
                    .background {
                        BrassPlateShape(cut: 10)
                            .fill(chosen ? Theatre.brassGlow : Theatre.ink3)
                    }
                    .overlay {
                        BrassPlateShape(cut: 10)
                            .strokeBorder(chosen ? Theatre.brass : Theatre.brassDeep.opacity(0.45),
                                          lineWidth: chosen ? 1 : 0.6)
                    }
                    .shadow(color: chosen ? Theatre.brassGlow : .clear, radius: 10)
                }
                .buttonStyle(BrassPressStyle())
            }
        }
    }

    /// The chosen board, so the pieces are judged where they will be seen.
    private var previewBoard: some View {
        let theme = BoardTheme(style: app.progress.appearance.board,
                               lightTone: app.progress.appearance.lightTone)
        return HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { column in
                ZStack {
                    (column % 2 == 0 ? theme.lightSquare : theme.darkSquare)
                    if let textures = theme.textures {
                        Image(column % 2 == 0 ? textures.light : textures.dark)
                            .resizable().scaledToFill()
                    }
                }
            }
        }
    }
}

private struct BoardGallery: View {
    @Environment(AppModel.self) private var app

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(BoardStyle.allCases) { style in
                let chosen = app.progress.appearance.board == style
                Button {
                    app.update { $0.appearance.board = style }
                } label: {
                    VStack(spacing: 7) {
                        MiniBoard(style: style)
                        Text(style.name)
                            .appFont(size: 9, weight: .medium)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background {
                        BrassPlateShape(cut: 10)
                            .fill(chosen ? Theatre.brassGlow : Theatre.ink3)
                    }
                    .overlay {
                        BrassPlateShape(cut: 10)
                            .strokeBorder(chosen ? Theatre.brass : Theatre.brassDeep.opacity(0.45),
                                          lineWidth: chosen ? 1 : 0.6)
                    }
                    .shadow(color: chosen ? Theatre.brassGlow : .clear, radius: 10)
                }
                .buttonStyle(BrassPressStyle())
            }
        }
    }
}

/// Four squares of the real thing, textures and all, with a piece standing on
/// it — a board is judged by what a piece looks like on it.
private struct MiniBoard: View {
    @Environment(\.pieceSet) private var pieceSet
    let style: BoardStyle
    var lightTone: LightTone = .boxwood
    /// Which side stands on it. A board is judged by the dark piece and the
    /// light side by the light one.
    var side: PieceColor = .black

    var body: some View {
        let theme = BoardTheme(style: style, lightTone: lightTone)
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<2, id: \.self) { column in
                            let isLight = (row + column) % 2 == 0
                            ZStack {
                                (isLight ? theme.lightSquare : theme.darkSquare)
                                if let textures = theme.textures {
                                    Image(isLight ? textures.light : textures.dark)
                                        .resizable().scaledToFill()
                                        .modifier(LightShade(tone: isLight ? lightTone : .boxwood))
                                }
                            }
                            .frame(width: 34, height: 34)
                        }
                    }
                }
            }
            PieceView(piece: Piece(side, .knight), size: 34, lightTone: lightTone)
                .offset(x: -17, y: 17)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theatre.rule, lineWidth: 0.5))
    }
}


/// Files and ranks round the edge of the board.
private struct CoordinatesSwitch: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Card {
            BrassToggle(
                L.t("settings.showFilesAndRanks", "Show files and ranks"),
                isOn: Binding(
                    get: { app.progress.appearance.showsCoordinates },
                    set: { on in app.update { $0.appearance.showsCoordinates = on } }
                )
            )
        }
    }
}

/// The shading applied to a light square or a white piece.
///
/// The same numbers the board itself is drawn with, so a swatch in the settings
/// is the thing rather than an impression of it.
private struct LightShade: ViewModifier {
    let tone: LightTone

    func body(content: Content) -> some View {
        let (multiply, lift) = tone.shading
        return content
            .colorMultiply(Color(red: multiply.0, green: multiply.1, blue: multiply.2))
            .brightness(lift)
    }
}

/// How light the light side is: snow, through the boxwood the set was
/// photographed in, to a pale blue.
///
/// Its own choice rather than part of the board, because it shades the pieces
/// as well as the squares — and somebody who finds ivory on cream hard to read
/// wants both moved, not one of them.
private struct LightToneGallery: View {
    @Environment(AppModel.self) private var app

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(LightTone.allCases) { tone in
                let chosen = app.progress.appearance.lightTone == tone
                Button {
                    app.update { $0.appearance.lightTone = tone }
                } label: {
                    VStack(spacing: 7) {
                        MiniBoard(style: app.progress.appearance.board, lightTone: tone, side: .white)
                        Text(tone.name)
                            .appFont(size: 9, weight: .medium)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background {
                        BrassPlateShape(cut: 10)
                            .fill(chosen ? Theatre.brassGlow : Theatre.ink3)
                    }
                    .overlay {
                        BrassPlateShape(cut: 10)
                            .strokeBorder(chosen ? Theatre.brass : Theatre.brassDeep.opacity(0.45),
                                          lineWidth: chosen ? 1 : 0.6)
                    }
                    .shadow(color: chosen ? Theatre.brassGlow : .clear, radius: 10)
                }
                .buttonStyle(BrassPressStyle())
            }
        }
    }
}

/// Flat or in the round, and which set stands on the round one.
///
/// Two choices rather than one list, because they are not alternatives: the
/// flat board's pieces and the turned board's pieces are different things made
/// in different ways, and the sets offered for one have nothing to say about
/// the other.
struct DimensionChoice: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var model = app
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                choice(
                    .flat,
                    L.t("settings.flat", "Flat"),
                    L.t("settings.flatNote", "Read from above. Arrows, hints and dragging a piece across the squares."),
                    "square.grid.3x3"
                )
                choice(
                    .dimensional,
                    L.t("settings.dimensional", "In the round"),
                    L.t("settings.dimensionalNote", "A turned set in a lit room. Drag to turn the board, tap to move."),
                    "cube"
                )
            }

            if app.progress.appearance.dimension.isDimensional {
                Text(L.t("settings.carving", "Set").uppercased())
                    .appFont(size: 9).tracking(2.2)
                    .foregroundStyle(Theatre.ivoryFaint)
                HStack(spacing: 9) {
                    carving(.banded, L.t("settings.banded", "Brass banded"))
                    carving(.plain, L.t("settings.plainSet", "Boxwood & ebony"))
                }
                Text(L.t("settings.dimensionalCaveat", "Arrows and move values are drawn on the flat board only."))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryFaint)
            }
        }
    }

    private func choice(_ value: BoardDimension, _ title: String, _ note: String, _ symbol: String) -> some View {
        let chosen = app.progress.appearance.dimension == value
        return Button {
            app.update { $0.appearance.dimension = value }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                BrassIcon(symbol, size: 23)
                    .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                Text(title)
                    .appFont(size: 11, weight: .medium).tracking(1.6)
                    .foregroundStyle(chosen ? Theatre.ivory : Theatre.ivoryDim)
                Text(note)
                    .appFont(.caption2)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background {
                BrassPlateShape(cut: 10)
                    .fill(chosen ? Theatre.brassGlow : Theatre.ink3)
            }
            .overlay {
                BrassPlateShape(cut: 10)
                    .strokeBorder(chosen ? Theatre.brass.opacity(0.72) : Theatre.brassDeep.opacity(0.45),
                                  lineWidth: 0.8)
            }
        }
        .buttonStyle(BrassPressStyle())
    }

    private func carving(_ value: Carving, _ title: String) -> some View {
        let chosen = app.progress.appearance.carving == value
        return Button {
            app.update { $0.appearance.carving = value }
        } label: {
            Text(title)
                .appFont(size: 10, weight: .medium).tracking(1.4)
                .foregroundStyle(chosen ? Theatre.ivory : Theatre.ivoryDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    BrassPlateShape(cut: 8)
                        .fill(chosen ? Theatre.brassGlow : Theatre.ink3)
                }
                .overlay {
                    BrassPlateShape(cut: 8)
                        .strokeBorder(chosen ? Theatre.brass.opacity(0.72) : Theatre.brassDeep.opacity(0.45),
                                      lineWidth: 0.8)
                }
        }
        .buttonStyle(BrassPressStyle())
    }
}

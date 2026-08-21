import ChessCore
import ChessTraining
import SwiftUI

/// A slim row at the top of every training screen: whatever the screen wants on
/// the right, and one predictable way back on the left.
struct TopBar<Content: View>: View {
    @Environment(ActivityGuard.self) private var activity
    @Environment(Navigator.self) private var navigator
    /// Set only by an online game. The row is empty during play anyway, and a
    /// clock is the one thing that has to be readable without looking away
    /// from the board.
    var clocks: ClockStrip?
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            BrassBackButton {
                if activity.isActive { activity.requestExit() } else { navigator.goToMenu() }
            }

            // Whatever the screen puts here — a mode picker, usually — is a way
            // out of the game as much as the tab bar is, so it goes away for
            // the same reason and comes back at the same moment.
            if activity.isActive {
                if let clocks { clocks } else { Spacer() }
            } else {
                content
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

struct SettingsScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("settings.settings", "Settings")) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section(L.t("settings.dimension", "Board")) { DimensionChoice() }
                    section(L.t("settings.pieces", "Pieces")) { PieceSetGallery() }
                    section(L.t("settings.squares", "Squares")) { BoardGallery() }
                    section(L.t("settings.sounds", "Move sounds")) { sound }
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
        Panel {
            BrassToggle(L.t("settings.soundsOn", "Play sounds"), isOn: Binding(
                get: { app.progress.appearance.soundsOn },
                set: { on in app.update { $0.appearance.soundsOn = on } }
            ))

            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption2).foregroundStyle(Theatre.ivoryFaint)
                BrassSlider(
                    value: Binding(
                        get: { app.progress.appearance.volume },
                        set: { level in app.update { $0.appearance.volume = level } }
                    ),
                    in: 0...1
                ) { editing in
                    // A sample on release, so the slider can be judged by ear
                    // rather than by the number next to it.
                    if !editing { SoundBoard.shared.play(.move) }
                }
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2).foregroundStyle(Theatre.ivoryFaint)
            }
            .opacity(app.progress.appearance.soundsOn ? 1 : 0.35)
            .disabled(!app.progress.appearance.soundsOn)
        }
    }

}

/// The sets, shown as themselves on a real square. Nobody picks "Ivory &
/// sapphire" from a word.
private struct PieceSetGallery: View {
    @Environment(AppModel.self) private var app

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(PieceSet.allCases) { set in
                let chosen = app.progress.appearance.pieces == set
                Button {
                    app.update { $0.appearance.pieces = set }
                    SoundBoard.shared.play(.move)
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            ForEach([PieceKind.king, .knight], id: \.rawValue) { kind in
                                PieceView(piece: Piece(.white, kind), size: 30)
                            }
                            ForEach([PieceKind.knight, .king], id: \.rawValue) { kind in
                                PieceView(piece: Piece(.black, kind), size: 30)
                            }
                        }
                        .environment(\.pieceSet, set)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background {
                            previewBoard.clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text(set.name)
                            .font(Face.mono(9, weight: .medium))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity)
                    .background(Theatre.ink3, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(chosen ? Theatre.brass : Theatre.rule, lineWidth: chosen ? 1 : 0.5)
                    )
                    .shadow(color: chosen ? Theatre.brassGlow : .clear, radius: 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The chosen board, so the pieces are judged where they will be seen.
    private var previewBoard: some View {
        let theme = BoardTheme(style: app.progress.appearance.board)
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
                            .font(Face.mono(9, weight: .medium))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Theatre.ink3, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(chosen ? Theatre.brass : Theatre.rule, lineWidth: chosen ? 1 : 0.5)
                    )
                    .shadow(color: chosen ? Theatre.brassGlow : .clear, radius: 10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Four squares of the real thing, textures and all, with a piece standing on
/// it — a board is judged by what a piece looks like on it.
private struct MiniBoard: View {
    @Environment(\.pieceSet) private var pieceSet
    let style: BoardStyle

    var body: some View {
        let theme = BoardTheme(style: style)
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
                                }
                            }
                            .frame(width: 34, height: 34)
                        }
                    }
                }
            }
            PieceView(piece: Piece(.black, .knight), size: 34)
                .offset(x: -17, y: 17)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theatre.rule, lineWidth: 0.5))
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
                    .font(Face.mono(9)).tracking(2.2)
                    .foregroundStyle(Theatre.ivoryFaint)
                HStack(spacing: 9) {
                    carving(.banded, L.t("settings.banded", "Brass banded"))
                    carving(.plain, L.t("settings.plainSet", "Boxwood & ebony"))
                }
                Text(L.t("settings.dimensionalCaveat", "Arrows and move values are drawn on the flat board only."))
                    .font(.footnote)
                    .foregroundStyle(Theatre.ivoryFaint)
            }
        }
    }

    private func choice(_ value: BoardDimension, _ title: String, _ note: String, _ symbol: String) -> some View {
        let chosen = app.progress.appearance.dimension == value
        return Button {
            app.update { $0.appearance.dimension = value }
            SoundBoard.shared.play(.move)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(chosen ? Theatre.brass : Theatre.ivoryDim)
                Text(title)
                    .font(Face.mono(11, weight: .medium)).tracking(1.6)
                    .foregroundStyle(chosen ? Theatre.ivory : Theatre.ivoryDim)
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(chosen ? Theatre.brassGlow : Theatre.ink3, in: RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(chosen ? Theatre.brass.opacity(0.5) : Theatre.rule, lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }

    private func carving(_ value: Carving, _ title: String) -> some View {
        let chosen = app.progress.appearance.carving == value
        return Button {
            app.update { $0.appearance.carving = value }
        } label: {
            Text(title)
                .font(Face.mono(10, weight: .medium)).tracking(1.4)
                .foregroundStyle(chosen ? Theatre.ivory : Theatre.ivoryDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(chosen ? Theatre.brassGlow : Theatre.ink3, in: Capsule())
                .overlay(Capsule().strokeBorder(chosen ? Theatre.brass.opacity(0.5) : Theatre.rule, lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }
}

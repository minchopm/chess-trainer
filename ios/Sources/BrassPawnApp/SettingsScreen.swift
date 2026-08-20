import ChessCore
import ChessTraining
import SwiftUI

/// The avatar in the corner of every screen.
///
/// One place, the same place on a phone and on an iPad, because a control that
/// moves depending on which tab you are in is a control people stop looking
/// for.
struct ProfileButton: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivityGuard.self) private var activity
    @State private var showsSettings = false

    var body: some View {
        Menu {
            Button {
                showsSettings = true
            } label: {
                Label(L.t("menu.profile", "Profile & settings"), systemImage: "person.crop.circle")
            }

            if activity.isActive {
                Divider()
                Button(role: .destructive) {
                    activity.requestExit()
                } label: {
                    Label(L.t("menu.leave", "Leave and go back"), systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            avatar
        }
        .accessibilityLabel(L.t("settings.profile", "Profile and settings"))
        .sheet(isPresented: $showsSettings) { SettingsScreen() }
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(.quaternary)
            if let photo = app.matchmaker.localPhoto {
                photo.resizable().scaledToFill().clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 30, height: 30)
        .overlay(Circle().strokeBorder(.quaternary, lineWidth: 0.5))
        .contentShape(Circle())
    }

    private var initials: String {
        let name = app.matchmaker.localName
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}

/// A slim row at the top of every training screen: whatever the screen wants on
/// the left, the profile on the right.
struct TopBar<Content: View>: View {
    @Environment(ActivityGuard.self) private var activity
    /// Set only by an online game. The row is empty during play anyway, and a
    /// clock is the one thing that has to be readable without looking away
    /// from the board.
    var clocks: ClockStrip?
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            // Whatever the screen puts here — a mode picker, usually — is a way
            // out of the game as much as the tab bar is, so it goes away for
            // the same reason and comes back at the same moment.
            if activity.isActive {
                if let clocks { clocks } else { Spacer() }
            } else {
                content
            }
            ProfileButton()
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    identity
                    section(L.t("settings.pieces", "Pieces")) { PieceSetGallery() }
                    section(L.t("settings.board", "Board")) { BoardGallery() }
                    section(L.t("settings.sounds", "Move sounds")) { sound }
                    section(L.t("settings.more", "More")) { more }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .background(Theatre.ink.ignoresSafeArea())
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L.t("settings.title", "Profile"))
                        .font(Face.display(20))
                        .foregroundStyle(Theatre.ivory)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("settings.done", "Done")) { dismiss() }
                        .font(Face.mono(11, weight: .medium))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Theatre.brass)
                }
            }
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

    private var identity: some View {
        Panel {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theatre.ink4)
                    Circle().strokeBorder(Theatre.brass.opacity(0.35), lineWidth: 1)
                    if let photo = app.matchmaker.localPhoto {
                        photo.resizable().scaledToFill().clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill").foregroundStyle(Theatre.brass.opacity(0.7))
                    }
                }
                .frame(width: 54, height: 54)
                .shadow(color: Theatre.brassGlow, radius: 12)

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.matchmaker.localName)
                        .font(Face.display(24))
                        .foregroundStyle(Theatre.ivory)
                    Text(L.t("settings.onlineRating", "Online rating %lld", app.progress.onlineRating))
                        .font(Face.mono(10))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theatre.ivoryFaint)
                }
                Spacer(minLength: 0)
            }

            if !app.matchmaker.isAuthenticated {
                Button(L.t("settings.signIn", "Sign in to Game Center")) {
                    app.matchmaker.authenticate()
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost))
                .padding(.top, 4)
            }
        }
    }

    private var sound: some View {
        Panel {
            Toggle(isOn: Binding(
                get: { app.progress.appearance.soundsOn },
                set: { on in app.update { $0.appearance.soundsOn = on } }
            )) {
                Text(L.t("settings.soundsOn", "Play sounds"))
                    .font(.subheadline)
                    .foregroundStyle(Theatre.ivory)
            }
            .tint(Theatre.brass)

            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption2).foregroundStyle(Theatre.ivoryFaint)
                Slider(
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
                .tint(Theatre.brass)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2).foregroundStyle(Theatre.ivoryFaint)
            }
            .opacity(app.progress.appearance.soundsOn ? 1 : 0.35)
            .disabled(!app.progress.appearance.soundsOn)
        }
    }

    private var more: some View {
        Panel(padding: 4) {
            ProUpsellRow()
                .padding(.horizontal, 12).padding(.vertical, 10)
            Divider().overlay(Theatre.ruleSoft)
            NavigationLink {
                AboutScreen()
            } label: {
                HStack {
                    Text(L.t("settings.about", "About & licence"))
                        .font(.subheadline).foregroundStyle(Theatre.ivory)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2).foregroundStyle(Theatre.ivoryFaint)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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

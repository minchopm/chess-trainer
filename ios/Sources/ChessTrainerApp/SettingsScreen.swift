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
    @State private var showsSettings = false

    var body: some View {
        Button { showsSettings = true } label: {
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
        .buttonStyle(.plain)
        .accessibilityLabel(L.t("settings.profile", "Profile and settings"))
        .sheet(isPresented: $showsSettings) { SettingsScreen() }
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
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            content
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
            List {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(.quaternary)
                            if let photo = app.matchmaker.localPhoto {
                                photo.resizable().scaledToFill().clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill").foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 52, height: 52)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.matchmaker.localName).font(.headline)
                            Text(L.t("settings.onlineRating", "Online rating %lld", app.progress.onlineRating))
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    if !app.matchmaker.isAuthenticated {
                        Button(L.t("settings.signIn", "Sign in to Game Center")) {
                            app.matchmaker.authenticate()
                        }
                    }
                }

                Section(L.t("settings.pieces", "Pieces")) {
                    PieceSetPicker()
                }

                Section(L.t("settings.board", "Board")) {
                    BoardStylePicker()
                }

                Section {
                    Toggle(L.t("settings.sounds", "Move sounds"), isOn: Binding(
                        get: { app.progress.appearance.soundsOn },
                        set: { on in app.update { $0.appearance.soundsOn = on } }
                    ))
                }

                Section {
                    ProUpsellRow()
                    NavigationLink(L.t("settings.about", "About & licence")) { AboutScreen() }
                }
            }
            .navigationTitle(L.t("settings.title", "Profile"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("settings.done", "Done")) { dismiss() }
                }
            }
        }
    }
}

/// Both sets, shown as themselves. A list of names would make somebody guess.
private struct PieceSetPicker: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ForEach(PieceSet.allCases) { set in
            Button {
                app.update { $0.appearance.pieces = set }
            } label: {
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        ForEach([PieceKind.king, .queen, .knight], id: \.rawValue) { kind in
                            PieceView(piece: Piece(.white, kind), size: 30)
                        }
                        ForEach([PieceKind.knight, .queen, .king], id: \.rawValue) { kind in
                            PieceView(piece: Piece(.black, kind), size: 30)
                        }
                    }
                    .environment(\.pieceSet, set)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color(red: 0.784, green: 0.580, blue: 0.365).opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 6))

                    Text(set.name)
                    Spacer()
                    if app.progress.appearance.pieces == set {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct BoardStylePicker: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ForEach(BoardStyle.allCases) { style in
            Button {
                app.update { $0.appearance.board = style }
            } label: {
                HStack(spacing: 12) {
                    MiniBoard(style: style)
                    Text(style.name)
                    Spacer()
                    if app.progress.appearance.board == style {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

/// Four squares of the real thing, textures and all.
private struct MiniBoard: View {
    let style: BoardStyle

    var body: some View {
        let theme = BoardTheme(style: style)
        VStack(spacing: 0) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { column in
                        let isLight = (row + column) % 2 == 0
                        ZStack {
                            (isLight ? theme.lightSquare : theme.darkSquare)
                            if let textures = theme.textures {
                                Image(isLight ? textures.light : textures.dark)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(width: 21, height: 21)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.quaternary, lineWidth: 0.5))
    }
}

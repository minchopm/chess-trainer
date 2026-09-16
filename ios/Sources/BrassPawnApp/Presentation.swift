import BoardUI
import ChessTraining
import SwiftUI

/// `fullScreenCover` and `sheet`, with the app's environment carried across.
///
/// On iOS a presented screen inherits the environment of whatever presented it,
/// which is why every screen in this app can simply say
/// `@Environment(AppModel.self)` and find one. On Mac Catalyst it does not: a
/// presentation there is hosted outside the view that asked for it, and what
/// the root put into the environment does not cross. The screen comes up, asks
/// for the model, finds nothing, and the app stops dead — Settings, the
/// purchase screen, the end of a puzzle, a game opened out of the history,
/// every one of them.
///
/// So the presenting side reads what it has and hands it on. Read rather than
/// rebuilt: whatever was in scope at the call site is exactly what the
/// presented screen gets, which is what iOS does, so nothing about the phone
/// changes. On the Mac it is the difference between an app and a crash.
///
/// Used in place of `fullScreenCover` and `sheet` throughout, rather than at
/// the places that happened to be found crashing — the next screen somebody
/// adds inherits the same problem, and the fix wants to be the obvious thing to
/// reach for rather than something to remember.
private struct CarriedEnvironment: ViewModifier {
    // The three shared objects. These are the ones that crash: an @Observable
    // put in with `.environment(_:)` has no default to fall back on, so a view
    // that asks for one and finds nothing traps rather than carries on.
    let app: AppModel
    let activity: ActivityGuard
    let navigator: Navigator

    // The board's appearance and the typeface. These have defaults, so losing
    // them is quiet rather than fatal — a puzzle would simply open on the wrong
    // board, in the wrong face, which is worse for being easy to miss.
    let boardTheme: BoardTheme
    let pieceSet: PieceSet
    let showsCoordinates: Bool
    let typeface: AppTypeface

    func body(content: Content) -> some View {
        content
            .environment(app)
            .environment(activity)
            .environment(navigator)
            .environment(\.boardTheme, boardTheme)
            .environment(\.pieceSet, pieceSet)
            .environment(\.showsBoardCoordinates, showsCoordinates)
            .appTypeface(typeface)
            // The same width rule the screens behind it keep, for the same
            // reason: a purchase screen spread across a thirty-inch display is
            // a paragraph forty words to the line. The ink underneath it is
            // painted here rather than left to the presented screen's own
            // background, which the cap would otherwise stop short of the
            // window's edges.
            .macContentWidth()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theatre.ink.ignoresSafeArea())
    }
}

/// Reads the environment at the presenting side so the presentation can put it
/// back. One type, because four presentation modifiers want the same seven
/// lines and a `@ViewBuilder` closure cannot reach an environment of its own.
///
/// `DynamicProperty` is what makes the nesting work: SwiftUI walks into a
/// conforming member of a view or modifier and updates the `@Environment`
/// properties inside it as if they had been declared there.
private struct Surroundings: DynamicProperty {
    @Environment(AppModel.self) private var app
    @Environment(ActivityGuard.self) private var activity
    @Environment(Navigator.self) private var navigator
    @Environment(\.boardTheme) private var boardTheme
    @Environment(\.pieceSet) private var pieceSet
    @Environment(\.showsBoardCoordinates) private var showsCoordinates
    @Environment(\.appTypeface) private var typeface

    init() {}

    var carried: CarriedEnvironment {
        CarriedEnvironment(
            app: app, activity: activity, navigator: navigator,
            boardTheme: boardTheme, pieceSet: pieceSet,
            showsCoordinates: showsCoordinates, typeface: typeface
        )
    }
}

private struct AppCover<Cover: View>: ViewModifier {
    var surroundings = Surroundings()
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    @ViewBuilder let cover: () -> Cover

    func body(content: Content) -> some View {
        let carried = surroundings.carried
        content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
            cover().modifier(carried)
        }
    }
}

private struct AppCoverItem<Item: Identifiable, Cover: View>: ViewModifier {
    var surroundings = Surroundings()
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    @ViewBuilder let cover: (Item) -> Cover

    func body(content: Content) -> some View {
        let carried = surroundings.carried
        content.fullScreenCover(item: $item, onDismiss: onDismiss) { value in
            cover(value).modifier(carried)
        }
    }
}

private struct AppSheet<Sheet: View>: ViewModifier {
    var surroundings = Surroundings()
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    @ViewBuilder let sheet: () -> Sheet

    func body(content: Content) -> some View {
        let carried = surroundings.carried
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
            sheet().modifier(carried)
        }
    }
}

private struct AppSheetItem<Item: Identifiable, Sheet: View>: ViewModifier {
    var surroundings = Surroundings()
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    @ViewBuilder let sheet: (Item) -> Sheet

    func body(content: Content) -> some View {
        let carried = surroundings.carried
        content.sheet(item: $item, onDismiss: onDismiss) { value in
            sheet(value).modifier(carried)
        }
    }
}

extension View {
    func appCover<Cover: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Cover
    ) -> some View {
        modifier(AppCover(isPresented: isPresented, onDismiss: onDismiss, cover: content))
    }

    func appCover<Item: Identifiable, Cover: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Cover
    ) -> some View {
        modifier(AppCoverItem(item: item, onDismiss: onDismiss, cover: content))
    }

    func appSheet<Sheet: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Sheet
    ) -> some View {
        modifier(AppSheet(isPresented: isPresented, onDismiss: onDismiss, sheet: content))
    }

    func appSheet<Item: Identifiable, Sheet: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Sheet
    ) -> some View {
        modifier(AppSheetItem(item: item, onDismiss: onDismiss, sheet: content))
    }
}

import SwiftUI

#if targetEnvironment(macCatalyst)
import UIKit
#endif

/// The handful of things the Mac build needs and the phone does not.
///
/// Mac Catalyst is the iOS app: the same views, the same engines, the same
/// board. What differs is the frame around it. A phone hands the app a screen
/// of a size nobody chose and a strip at the top that belongs to the system; a
/// Mac hands it a window somebody can drag to any shape at all, with three
/// buttons floating over the top-left corner. Both of those want answering, and
/// neither is worth an `#if` at every call site — hence the constants here.
///
/// `isCatalyst` is a stored constant rather than a compile-time branch on
/// purpose: it reads as a value in an expression, which is what the layout code
/// wants, and the optimiser folds it away on both platforms anyway.
enum Mac {
    #if targetEnvironment(macCatalyst)
    static let isCatalyst = true
    #else
    static let isCatalyst = false
    #endif

    /// The smallest window the app is still worth using in.
    ///
    /// Wide enough that the board and the panel beside it both get a usable
    /// share — below about eight hundred points the panel is narrower than its
    /// own paragraph and the layout stops being a layout. Tall enough that the
    /// board is limited by the width rather than squeezed by the height: the
    /// board takes the window's height less the two rows of chrome, so a short
    /// window shrinks the one thing nobody wants shrunk.
    static let minimumWindowSize = CGSize(width: 880, height: 660)

    /// How wide the laid-out screens are allowed to get before they stop
    /// growing and simply centre themselves.
    ///
    /// Every screen in the app is a board with a column of text beside it, and
    /// both have caps of their own. This is their sum — the widest the
    /// composition can actually use. Past it a wider window stops adding
    /// anything and starts pulling the two apart, until the board is against
    /// one edge and the reading against the other with a stretch of empty ink
    /// between them. A 6K display is two and a half times this wide.
    ///
    /// Taken from the layout rather than written down again, so that raising
    /// either cap widens the window that holds them instead of quietly
    /// squeezing one of the two.
    ///
    /// The title screen is deliberately not capped: it is a photograph of a
    /// room, and a photograph should fill the frame it is given.
    static var contentWidth: CGFloat {
        TrainingLayout<EmptyView, EmptyView, EmptyView>.maximumWide
    }

    /// How far the back button sits above its own row.
    ///
    /// On iOS it is lifted into the strip the hidden status bar leaves free —
    /// a row of its own for one round button is a row the screen could have
    /// used. On a Mac that strip is the title bar, and the window's own close,
    /// minimise and zoom buttons are already in it. Lifting the button there
    /// puts it underneath them.
    static var backButtonLift: CGFloat { isCatalyst ? 0 : -26 }

    /// Headroom above the top row.
    ///
    /// Four points on iOS, where the button is lifted clear. On a Mac the
    /// button stays in the row, so the row has to start low enough that a
    /// 44-point circle centred in it clears the window buttons above.
    static var topBarHeadroom: CGFloat { isCatalyst ? 14 : 4 }
}

#if targetEnvironment(macCatalyst)
/// Reaches the `UIWindowScene` the SwiftUI hierarchy has been placed in.
///
/// There is no SwiftUI way to say how small a window may be dragged, and the
/// answer lives on `UIWindowScene.sizeRestrictions`, which the scene owns. A
/// zero-sized view in the background is the shortest route to the scene from
/// inside a `View`: it is put in a window like anything else, and `didMoveToWindow`
/// is the moment the window exists.
private struct WindowSceneReader: UIViewRepresentable {
    let configure: (UIWindowScene) -> Void

    func makeUIView(context: Context) -> UIView { Probe(configure: configure) }
    func updateUIView(_ view: UIView, context: Context) {}

    private final class Probe: UIView {
        private let configure: (UIWindowScene) -> Void

        init(configure: @escaping (UIWindowScene) -> Void) {
            self.configure = configure
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not from a nib") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene else { return }
            configure(scene)
        }
    }
}
#endif

public extension View {
    /// Settles the window the app is shown in: how small it may be dragged,
    /// and what the title bar says.
    ///
    /// Nothing on iOS, where there is no window to settle. Public because the
    /// scene it applies to is declared in the app target, not in here.
    func macWindow() -> some View {
        #if targetEnvironment(macCatalyst)
        background {
            WindowSceneReader { scene in
                scene.sizeRestrictions?.minimumSize = Mac.minimumWindowSize

                // No title and no toolbar. The app draws its own name on the
                // screen below in the face it chose, twice the size and in the
                // right colour; the system's copy of it in the title bar is the
                // one piece of furniture on screen the app did not put there.
                // The bar stays — it is where the window's buttons live — and
                // with nothing in it, it is the same ink as everything else.
                scene.titlebar?.titleVisibility = .hidden
                scene.titlebar?.toolbar = nil
            }
            .accessibilityHidden(true)
        }
        #else
        self
        #endif
    }

    /// Keeps a screen from stretching past the width it was designed for.
    ///
    /// Applied on the Mac, where the window is whatever width somebody dragged
    /// it to. Nothing on iOS, where the widest screen is an iPad and the
    /// layouts already have its measure.
    internal func macContentWidth() -> some View {
        frame(maxWidth: Mac.isCatalyst ? Mac.contentWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

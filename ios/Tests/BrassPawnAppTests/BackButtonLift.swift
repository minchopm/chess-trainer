import SwiftUI
import Testing
@testable import BrassPawnApp

/// The way out of a game has to be on the screen.
///
/// The top bar is a thirty-point row and the button is a forty-four point
/// circle, so the circle stands seven points proud of the row before anything
/// lifts it at all. On top of that it is lifted into the strip the hidden
/// status bar leaves free — and that strip is a different height on every
/// device. A flat lift took the top off the circle on an iPad, which is a
/// fault you only see on the one device you did not open the simulator on.
@Suite("back button lift", .enabled(if: !Mac.isCatalyst, "the Mac keeps it in the row"))
struct BackButtonLift {
    /// The strip each device leaves above the row: its top safe area plus the
    /// bar's own headroom.
    static let phoneWithIsland: CGFloat = 59 + 4
    static let phoneLandscape: CGFloat = 0 + 4
    static let tablet: CGFloat = 24 + 4

    /// Where the circle's top edge ends up, which is the whole question.
    static func top(above row: CGFloat, rowHeight: CGFloat) -> CGFloat {
        row + (rowHeight - BrassBackButton.diameter) / 2
            + BrassBackButton.lift(above: row, rowHeight: rowHeight)
    }

    @Test("the whole circle is on the screen", arguments: [
        phoneWithIsland, phoneLandscape, tablet,
    ], [TopBar<EmptyView>.rowHeight, 0])
    func wholeCircleIsOnScreen(row: CGFloat, rowHeight: CGFloat) {
        let top = Self.top(above: row, rowHeight: rowHeight)
        #expect(top >= 0, "\(top) points from the top of the window")
        // Not against the very edge either: the corners of every screen it runs
        // on are rounded, and the button sits in one of them.
        #expect(top >= 5)
    }

    /// A phone has strip to spare, and the button still takes the same
    /// twenty-six points of it that made a row of its own unnecessary.
    @Test("a phone is unchanged")
    func phoneIsUnchanged() {
        #expect(
            BrassBackButton.lift(above: Self.phoneWithIsland,
                                 rowHeight: TopBar<EmptyView>.rowHeight) == -26
        )
    }

    /// An iPad has less, and takes less.
    @Test("a tablet takes what there is")
    func tabletTakesWhatThereIs() {
        let lift = BrassBackButton.lift(above: Self.tablet,
                                        rowHeight: TopBar<EmptyView>.rowHeight)
        #expect(lift > -26, "a tablet cannot afford the full lift")
        #expect(lift < 0, "and it can afford some of it")
    }

    /// A phone held sideways has none at all, and the button comes *down* into
    /// the row rather than half off the top of the screen.
    @Test("no strip means no lift")
    func noStripMeansNoLift() {
        #expect(
            BrassBackButton.lift(above: Self.phoneLandscape,
                                 rowHeight: TopBar<EmptyView>.rowHeight) > 0
        )
    }
}

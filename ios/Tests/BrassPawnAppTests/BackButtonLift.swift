import SwiftUI
import Testing
@testable import BrassPawnApp

/// The way out of a game has to be on the screen, and only on its own row.
///
/// The top bar is a thirty-point row and the button is a forty-four point
/// circle centred on it, so the circle stands seven points proud at each end
/// before anything moves it. Above, that is the point: it uses the strip the
/// hidden status bar leaves free. But that strip is a different height on every
/// device — close to sixty points on a phone with an island, nothing at all on
/// an iPad or on a phone held sideways — and a flat lift first took the top off
/// the circle on an iPad and then, corrected, pushed its foot down onto the
/// opponent's name. Both are faults you see on one device and not the next.
@Suite("back button lift", .enabled(if: !Mac.isCatalyst, "the Mac keeps it in the row"))
struct BackButtonLift {
    /// What each device leaves above the bar.
    static let phoneWithIsland: CGFloat = 59
    static let olderPhone: CGFloat = 47
    /// An iPad with the status bar hidden keeps none of it, and neither does a
    /// phone turned on its side.
    static let noStrip: CGFloat = 0

    static let strips = [phoneWithIsland, olderPhone, noStrip]
    static let rows = [TopBar<EmptyView>.rowHeight, 0]

    /// The bar as it is actually built: the strip, then whichever headroom is
    /// larger — the platform's or the one the button asks for.
    static func circle(strip: CGFloat, rowHeight: CGFloat)
        -> (top: CGFloat, foot: CGFloat, rowFoot: CGFloat)
    {
        let row = strip + max(Mac.topBarHeadroom,
                             BrassBackButton.headroom(strip: strip, rowHeight: rowHeight))
        let top = row + (rowHeight - BrassBackButton.diameter) / 2
            + BrassBackButton.lift(above: row, rowHeight: rowHeight)
        return (top, top + BrassBackButton.diameter, row + rowHeight)
    }

    @Test("the whole circle is on the screen", arguments: strips, rows)
    func wholeCircleIsOnScreen(strip: CGFloat, rowHeight: CGFloat) {
        let circle = Self.circle(strip: strip, rowHeight: rowHeight)
        // Not against the very edge either: every screen it runs on has rounded
        // corners and the button sits in one of them.
        #expect(circle.top >= 5, "\(circle.top) points from the top of the window")
    }

    /// And it stays in its own row. Below the row is the opponent's name.
    @Test("it does not come out of the bottom of its row", arguments: strips, rows)
    func staysInItsRow(strip: CGFloat, rowHeight: CGFloat) {
        let circle = Self.circle(strip: strip, rowHeight: rowHeight)
        #expect(circle.foot <= circle.rowFoot,
                "\(circle.foot - circle.rowFoot) points past the foot of the row")
    }

    /// A phone has strip to spare, so the bar starts where it always did and
    /// the button still takes the twenty-six points that made a row of its own
    /// unnecessary in the first place.
    @Test("a phone is unchanged", arguments: [phoneWithIsland, olderPhone])
    func phoneIsUnchanged(strip: CGFloat) {
        let row = TopBar<EmptyView>.rowHeight
        #expect(BrassBackButton.headroom(strip: strip, rowHeight: row) == 0)
        #expect(BrassBackButton.lift(above: strip + Mac.topBarHeadroom, rowHeight: row) == -26)
    }

    /// Where there is none, the row makes one rather than the button leaving
    /// the screen or landing on the row below.
    @Test("no strip means the row makes one")
    func noStripMeansTheRowMakesOne() {
        let row = TopBar<EmptyView>.rowHeight
        #expect(BrassBackButton.headroom(strip: Self.noStrip, rowHeight: row) > Mac.topBarHeadroom)
    }
}

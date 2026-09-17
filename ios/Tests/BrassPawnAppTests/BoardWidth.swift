import SwiftUI
import Testing
@testable import BrassPawnApp

/// How wide the board comes out, on each device and in each layout.
///
/// It was not: a reading cap meant for a screen held at arm's length was
/// applied on top of the screen's own width, and on a thirteen-inch iPad that
/// left a hundred points of dead ink down either side of the board while the
/// screen had the room. The fault only shows on a tablet — on a phone the width
/// was always the binding constraint — so it is exactly the case a look at the
/// simulator on a phone would miss.
@Suite("board width")
struct BoardWidth {
    typealias Layout = TrainingLayout<EmptyView, EmptyView, EmptyView>

    /// Every real device gives the board its width.
    ///
    /// These are layout heights, not screen heights — what is left of the
    /// screen once the tab bar and the safe areas have had theirs, which is
    /// roughly sixty points on an iPad and rather more on a phone. It is the
    /// pessimistic reading on purpose: the fraction this replaced looked
    /// generous against a screen height and was still holding back forty points
    /// a side against the real one.
    @Test("the width decides", arguments: [
        CGSize(width: 1024, height: 1300),   // iPad Pro 13"
        CGSize(width: 834, height: 1130),    // iPad Pro 11"
        CGSize(width: 820, height: 1120),    // iPad Air
        CGSize(width: 744, height: 1070),    // iPad mini
        CGSize(width: 440, height: 800),     // iPhone Pro Max
        CGSize(width: 393, height: 700),     // iPhone Pro
        CGSize(width: 375, height: 560),     // the smallest still sold
    ])
    func widthDecides(size: CGSize) {
        #expect(Layout.portraitBoard(in: size) == size.width - 20)
    }

    /// And the panel below it still has somewhere to be.
    ///
    /// Growing the board is only an improvement while what follows it — the
    /// coach's paragraph, the controls — is still on the screen underneath. The
    /// floor is what the height is for now; a window short enough to reach it
    /// gets a smaller board rather than buttons it cannot see.
    @Test("the panel still has room", arguments: [
        CGSize(width: 1024, height: 1300),
        CGSize(width: 834, height: 1130),
        CGSize(width: 375, height: 560),
        CGSize(width: 600, height: 620),     // short enough that the floor bites
        CGSize(width: 500, height: 420),
    ])
    func panelStillHasRoom(size: CGSize) {
        let stage = Layout.portraitBoard(in: size) + BoardStage<EmptyView>.chromeHeight
        #expect(
            size.height - stage >= Layout.minimumBelowBoard,
            "\(size.height - stage) points left under the board"
        )
    }

    /// The column beside the board ends where the board ends.
    ///
    /// The wide layout pins the column to the board's height so that the
    /// controls at its foot stand level with the foot of the board rather than
    /// alone at the bottom of the window. That only holds while the height it
    /// pins is the height the stage actually stands at — and a stage with the
    /// evaluation bar down its side is shorter than the width it was handed,
    /// because the bar and the strip facing it come out of that width.
    @Test("the column ends where the board does", arguments: [
        CGSize(width: 1366, height: 1024),   // iPad Pro 13" landscape
        CGSize(width: 1194, height: 834),    // iPad Pro 11" landscape
        CGSize(width: 1460, height: 900),    // a roomy Mac window
        CGSize(width: 880, height: 660),     // the smallest Mac window allowed
    ])
    func columnEndsWhereBoardDoes(size: CGSize) {
        for showsEvaluation in [true, false] {
            let side = Layout.wideBoard(in: size, showsEvaluation: showsEvaluation)
            let gutters = showsEvaluation ? BoardStage<EmptyView>.gutters : 0
            // What the stage is handed, and what it stands at once it has it.
            let stands = BoardStage<EmptyView>.boardSide(
                in: side + gutters, showsEvaluation: showsEvaluation
            )
            #expect(stands == side, "\(size) with bar: \(showsEvaluation)")
        }
    }

    /// And the panel beside it is never squeezed below the width it was
    /// written for — the bar comes out of the board's share, not the panel's.
    @Test("the panel beside it keeps its width", arguments: [
        CGSize(width: 1366, height: 1024),
        CGSize(width: 1194, height: 834),
        CGSize(width: 880, height: 660),
    ])
    func panelKeepsItsWidth(size: CGSize) {
        let stage = Layout.wideBoard(in: size, showsEvaluation: true)
            + BoardStage<EmptyView>.gutters
        let panel = size.width - Layout.wideSurround - stage
        #expect(panel >= Layout.minimumPanel, "\(panel) points of panel")
    }
}

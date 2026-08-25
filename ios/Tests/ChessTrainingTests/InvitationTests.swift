import Foundation
import Testing
@testable import ChessTraining

@Suite("An invitation to a game")
struct InvitationTests {
    private let sample = Invitation(name: "Мартин", playerID: "G:1234567890", minutes: 5)

    @Test("Survives the trip through a chat window")
    func roundTrips() {
        let back = Invitation(encoded: sample.encoded)
        #expect(back == sample)
    }

    @Test("Carries a name that is not written in ASCII")
    func carriesUnicode() throws {
        let back = try #require(Invitation(encoded: sample.encoded))
        #expect(back.name == "Мартин")
    }

    /// Base64 with `+`, `/` and `=` in it does not survive a URL, and half the
    /// point of the link is that it can be pasted anywhere.
    @Test("Encodes with nothing a URL would object to")
    func urlSafe() {
        let code = sample.encoded
        #expect(!code.contains("+"))
        #expect(!code.contains("/"))
        #expect(!code.contains("="))
    }

    @Test("Reads back out of the link it builds")
    func readsFromLink() throws {
        let back = try #require(Invitation(url: sample.link))
        #expect(back == sample)
    }

    @Test("The link names the clip, so iOS knows what to fetch")
    func linkNamesTheClip() {
        let text = sample.link.absoluteString
        #expect(text.hasPrefix("https://appclip.apple.com/id?"))
        #expect(text.contains("p=com.arte-soft.brasspawn.Clip"))
    }

    @Test("A URL with no invitation in it is not one")
    func rejectsPlainURLs() {
        #expect(Invitation(url: URL(string: "https://appclip.apple.com/id?p=x")!) == nil)
        #expect(Invitation(encoded: "not base64 at all !!") == nil)
    }

    /// The whole mechanism rests on this: both devices compute the pool from
    /// the same link, without talking to each other first.
    @Test("Both ends land in the same pool")
    func poolIsStable() {
        let theirs = Invitation(encoded: sample.encoded)
        #expect(theirs?.playerGroup == sample.playerGroup)
    }

    @Test("A different player, or a different clock, is a different pool")
    func poolSeparates() {
        let otherPlayer = Invitation(name: "Мартин", playerID: "G:9999999999", minutes: 5)
        let otherClock = Invitation(name: "Мартин", playerID: "G:1234567890", minutes: 10)
        #expect(otherPlayer.playerGroup != sample.playerGroup)
        #expect(otherClock.playerGroup != sample.playerGroup)
    }

    /// Game Center's ordinary pools are the five clocks, at 4003…4030. An
    /// invitation that landed on one of those would find a stranger.
    @Test("An invitation's pool is never one of the clocks'")
    func poolAvoidsTheClocks() {
        let clocks = Set(TimeControl.allCases.map(\.playerGroup))
        for id in 0..<500 {
            let invitation = Invitation(name: "x", playerID: "G:\(id)", minutes: 5)
            #expect(!clocks.contains(invitation.playerGroup))
        }
    }
}

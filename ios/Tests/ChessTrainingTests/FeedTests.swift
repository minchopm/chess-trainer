import ChessCore
import Foundation
import Testing
@testable import ChessTraining

/// The daily feed, as the app reads it.
@Suite("The daily feed")
struct FeedTests {
    /// One story as publish.mjs writes it, with the moves and the key moment
    /// replaced to suit the test.
    private func story(id: String = "2026-09-25-a-b-olympiad-r9", result: String = "0-1",
                       moves: String = "f3 e5 g4 Qh4#", key: String? = nil) -> String {
        """
        {"id":"\(id)","date":"2026-09-25",
         "event":{"name":"46th FIDE Chess Olympiad Samarkand 2026","short":"Olympiad","section":"Open","round":9,"location":"Samarkand, Uzbekistan","url":null},
         "white":{"name":"Anna White","short":"White","title":"GM","elo":2700,"team":null},
         "black":{"name":"Boris Black","short":"Black","title":"GM","elo":2710,"team":"Uzbekistan"},
         "result":"\(result)","opening":{"eco":"A00","name":"Barnes Opening"},
         "moves":"\(moves)","key":\(key ?? "null"),
         "headline":"Black mates in two","body":"It was over on move two.",
         "url":"https://brasspawn.com/today/\(id)","source":{"name":"Lichess broadcast","url":null}}
        """
    }

    private func file(version: Int = 1, _ stories: String...) -> Data {
        Data("""
        {"version":\(version),"generatedAt":"2026-09-26T08:00:00.000Z",
         "source":{"name":"Lichess broadcasts","url":"https://lichess.org/broadcast"},
         "stories":[\(stories.joined(separator: ","))]}
        """.utf8)
    }

    private let key = """
    {"kind":"mistake","ply":3,"played":"g4","better":"Nc3","reply":"Qh4#","replyPlayed":true,
     "before":{"cp":-150,"mate":null},"after":{"cp":null,"mate":-1}}
    """

    @Test("a file as publish.mjs writes it is read")
    func readsTheFile() throws {
        let feed = try FeedFile.decode(file(story(key: key)))
        #expect(feed.stories.count == 1)
        let story = try #require(feed.stories.first)
        #expect(story.winner == .black)
        #expect(story.sans == ["f3", "e5", "g4", "Qh4#"])
        #expect(story.key?.ply == 3)
        #expect(story.event.round == 9)
    }

    /// A replay that stops halfway is worse than no story: nobody watching can
    /// tell whether the game or the app is at fault.
    @Test("a story whose moves do not play is left out")
    func dropsIllegalLines() throws {
        let feed = try FeedFile.decode(file(story(id: "good"), story(id: "bad", moves: "e4 e5 Ke3")))
        #expect(feed.stories.map(\.id) == ["good"])
    }

    /// The first file lists every day; the days not in it are fetched one at
    /// a time as the reader goes back.
    @Test("the first file lists the days behind it")
    func readsTheDayIndex() throws {
        let data = Data("""
        {"version":1,"generatedAt":"2026-09-26T08:00:00Z",
         "days":[{"date":"2026-09-25","count":1},{"date":"2026-09-24","count":7}],
         "stories":[\(story())]}
        """.utf8)
        let feed = try FeedFile.decode(data)
        #expect(feed.days?.map(\.date) == ["2026-09-25", "2026-09-24"])
        #expect(feed.days?.last?.count == 7)
    }

    @Test("a day's file is read, and a story in it whose moves do not play is left out")
    func readsADay() throws {
        let data = Data("""
        {"date":"2026-09-24","stories":[\(story(id: "good")),\(story(id: "bad", moves: "e4 e5 Ke3"))]}
        """.utf8)
        let day = try FeedDay.decode(data)
        #expect(day.date == "2026-09-24")
        #expect(day.stories.map(\.id) == ["good"])
    }

    /// The collector writes fields the app has no use for — the status, the
    /// board worked out for the site — and they must not stop it reading.
    @Test("fields the app does not know are ignored")
    func ignoresExtraFields() throws {
        let extra = story().replacingOccurrences(
            of: "\"id\":", with: "\"status\":\"auto\",\"rank\":0,\"fen\":\"8/8/8/8/8/8/8/8 w - - 0 1\",\"id\":")
        #expect(try FeedFile.decode(file(extra)).stories.count == 1)
    }

    @Test("a version this build does not know is refused rather than half read")
    func refusesLaterVersions() {
        #expect(throws: FeedError.unsupportedVersion(2)) {
            try FeedFile.decode(file(version: 2, story()))
        }
    }

    @Test("the board shown is the one after the key move")
    func focusIsAfterTheKeyMove() throws {
        let story = try #require(try FeedFile.decode(file(story(key: key))).stories.first)
        let focus = story.focus
        #expect(focus.lastMove?.from == Square(file: 6, rank: 1))
        #expect(focus.lastMove?.to == Square(file: 6, rank: 3))
        #expect(focus.position.sideToMove == .black)
    }

    /// The collector stores the board, and the list reads it rather than
    /// replaying a game for every row it draws.
    @Test("a stored position is used as it is")
    func focusFromTheStoredPosition() throws {
        let withBoard = story(key: key).replacingOccurrences(
            of: "\"id\":",
            with: "\"fen\":\"rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2\",\"last\":{\"from\":\"g2\",\"to\":\"g4\"},\"id\":")
        let story = try #require(try FeedFile.decode(file(withBoard)).stories.first)
        let focus = story.focus
        #expect(focus.position.fen.hasPrefix("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2"))
        #expect(focus.lastMove?.from == Square("g2"))
        #expect(focus.lastMove?.to == Square("g4"))
    }

    @Test("without a key moment, the board is the final one")
    func focusWithoutAKeyIsTheEnd() throws {
        let story = try #require(try FeedFile.decode(file(story())).stories.first)
        #expect(story.focusPly == 4)
        #expect(story.focus.position.isCheckmate)
    }

    @Test("moves are labelled the way the commentary writes them")
    func moveLabels() {
        #expect(FeedStory.label(ply: 3, san: "g4") == "2.g4")
        #expect(FeedStory.label(ply: 80, san: "Rxb3") == "40...Rxb3")
    }

    @Test("the headline the app builds names the winner first")
    func titleNamesTheWinner() throws {
        let black = try #require(try FeedFile.decode(file(story(result: "0-1"))).stories.first)
        #expect(black.title == "Black beat White")
        let white = try #require(try FeedFile.decode(file(story(result: "1-0", moves: "e4"))).stories.first)
        #expect(white.title == "White beat Black")
        let draw = try #require(try FeedFile.decode(file(story(result: "1/2-1/2", moves: "e4"))).stories.first)
        #expect(draw.title == "White and Black drew")
        #expect(draw.occasion == "Olympiad · Open · Round 9")
    }

    @Test("every address a story travels by leads to it, and nothing else does")
    func storyLinks() {
        let id = "2026-09-25-so-sindarov-olympiad-r9"
        #expect(FeedLink.storyID(in: URL(string: "brasspawn://today/\(id)")!) == id)
        #expect(FeedLink.storyID(in: FeedLink.clip(for: id)) == id)
        #expect(FeedLink.storyID(in: URL(string: "https://brasspawn.com/today/\(id)")!) == id)
        #expect(FeedLink.storyID(in: URL(string: "https://brasspawn.com/today/story?id=\(id)")!) == id)
        #expect(FeedLink.storyID(in: URL(string: "brasspawn://today/")!) == nil)
        #expect(FeedLink.storyID(in: URL(string: "brasspawn://today/../settings")!) == nil)
        #expect(FeedLink.storyID(in: URL(string: "https://brasspawn.com/today")!) == nil)
        #expect(FeedLink.storyID(in: URL(string: "https://evil.example/today/\(id)")!) == nil)
        // An invitation's clip link has no story in it, and must still read
        // as an invitation.
        let invitation = Invitation(name: "Ana", playerID: "G:1", minutes: 5)
        #expect(FeedLink.storyID(in: invitation.link) == nil)
        #expect(Invitation(url: FeedLink.clip(for: id)) == nil)
    }

    @Test("each language the app speaks reads its own copy of the feed, and English the top level")
    func feedFolders() {
        #expect(FeedLink.folder(for: "en") == nil)
        #expect(FeedLink.folder(for: "en-US") == nil)
        #expect(FeedLink.folder(for: "de-DE") == "de")
        #expect(FeedLink.folder(for: "fr-CA") == "fr")
        #expect(FeedLink.folder(for: "ar-SA") == "ar")
        #expect(FeedLink.folder(for: "pt-BR") == "pt-BR")
        #expect(FeedLink.folder(for: "zh-Hans") == "zh-Hans")
        #expect(FeedLink.folder(for: "zh-Hant") == "zh-Hant")
        #expect(FeedLink.folder(for: "no") == "no")
        // A language the feed is not written in reads the English.
        #expect(FeedLink.folder(for: "bg") == nil)
    }

    @Test("a story in another language's copy says which language its words are in")
    func storyLanguage() throws {
        let json = #"{"id":"x","date":"2026-09-26","event":{"name":"E","short":"E","section":null,"round":1,"location":null,"url":null},"white":{"name":"A B","short":"B","title":null,"elo":null,"team":null},"black":{"name":"C D","short":"D","title":null,"elo":null,"team":null},"result":"1-0","opening":{"eco":null,"name":null},"moves":"e4 e5","key":null,"headline":"B – D 1–0: Sieg für Weiß","body":"…","lang":"de","url":"https://brasspawn.com/today/x","source":{"name":"Lichess broadcast","url":null}}"#
        let story = try JSONDecoder().decode(FeedStory.self, from: Data(json.utf8))
        #expect(story.lang == "de")
        let english = try JSONDecoder().decode(FeedStory.self, from: Data(json.replacingOccurrences(of: #","lang":"de""#, with: "").utf8))
        #expect(english.lang == nil)
    }

    @Test("a link from the site carries the move the reader had reached, and only a move")
    func storyLinksAtAMove() {
        let id = "2026-09-25-so-sindarov-olympiad-r9"
        let at = FeedLink.Target(id: id, ply: 86)
        #expect(FeedLink.target(in: URL(string: "brasspawn://today/\(id)?ply=86")!) == at)
        #expect(FeedLink.target(in: FeedLink.clip(for: id, ply: 86)) == at)
        #expect(FeedLink.target(in: URL(string: "https://brasspawn.com/today/\(id)?ply=86")!) == at)
        #expect(FeedLink.target(in: URL(string: "https://brasspawn.com/today/story?id=\(id)&ply=86")!) == at)
        // Without one, the story opens where it always has.
        #expect(FeedLink.target(in: FeedLink.clip(for: id)) == FeedLink.Target(id: id))
        // Anything that is not a move in a game is no move, and the story
        // still opens.
        for junk in ["-3", "4.5", "abc", "99999", ""] {
            #expect(FeedLink.target(in: URL(string: "brasspawn://today/\(id)?ply=\(junk)")!) == FeedLink.Target(id: id))
        }
        // The clip's link keeps the story first, where an older clip looks.
        #expect(FeedLink.storyID(in: FeedLink.clip(for: id, ply: 3)) == id)
        #expect(Invitation(url: FeedLink.clip(for: id, ply: 3)) == nil)
    }

    @Test("an engine score reads as a number from White's side")
    func scoreText() {
        #expect(FeedStory.Score(cp: 108, mate: nil).text.hasPrefix("+1"))
        #expect(FeedStory.Score(cp: -440, mate: nil).text.hasPrefix("−4"))
        #expect(FeedStory.Score(cp: nil, mate: 3).text == "#3")
        #expect(FeedStory.Score(cp: nil, mate: -2).text == "#−2")
    }
}

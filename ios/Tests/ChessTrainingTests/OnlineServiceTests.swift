import ChessCore
import Foundation
import Testing
@testable import ChessTraining

/// Thread-safe mock HTTP transport for `OnlineAPI` unit tests.
private actor MockHTTPState {
    struct RecordedRequest: Sendable {
        let method: String
        let url: URL
        let headers: [String: String]
        let body: Data?
        let timeout: TimeInterval
    }

    var requests: [RecordedRequest] = []
    var inFlight = 0
    var maxConcurrentInFlight = 0
    private var handlers: [@Sendable (RecordedRequest) async throws -> OnlineHTTPResponse] = []
    var fallback: @Sendable (RecordedRequest) async throws -> OnlineHTTPResponse = { _ in
        OnlineHTTPResponse(status: 200, body: Data("{\"ok\":true}".utf8))
    }

    func enqueue(_ handler: @escaping @Sendable (RecordedRequest) async throws -> OnlineHTTPResponse) {
        handlers.append(handler)
    }

    func handle(_ request: RecordedRequest) async throws -> OnlineHTTPResponse {
        inFlight += 1
        maxConcurrentInFlight = max(maxConcurrentInFlight, inFlight)
        defer { inFlight -= 1 }
        requests.append(request)
        if !handlers.isEmpty {
            let next = handlers.removeFirst()
            return try await next(request)
        }
        return try await fallback(request)
    }

    func allRequests() -> [RecordedRequest] { requests }
    func peakInFlight() -> Int { maxConcurrentInFlight }
}

private final class MockOnlineTransport: OnlineHTTPTransport {
    let state = MockHTTPState()

    func send(
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?,
        timeout: TimeInterval
    ) async throws -> OnlineHTTPResponse {
        let recorded = MockHTTPState.RecordedRequest(
            method: method, url: url, headers: headers, body: body, timeout: timeout
        )
        return try await state.handle(recorded)
    }
}

private func jsonResponse(_ status: Int = 200, _ object: [String: Any]) -> OnlineHTTPResponse {
    let data = try! JSONSerialization.data(withJSONObject: object)
    return OnlineHTTPResponse(status: status, body: data)
}

private func decodeJSON(_ data: Data?) -> [String: Any] {
    guard let data, let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
        return [:]
    }
    return obj
}

@Suite("Online service wire protocol & session flow")
@MainActor
struct OnlineServiceTests {

    @Test("applyServerResult sets server delta and deviation and prevents duplicate settle")
    func applyServerResultOnSession() throws {
        final class NoopTransport: MatchTransport { func send(_ data: Data) {} }
        let transport = NoopTransport()
        let host = MatchSession(
            transport: transport,
            me: .init(playerID: "host", name: "Host", rating: 1200, games: 0),
            isHost: true,
            timeControl: .five
        )
        host.begin(whiteIsHost: true)
        let guestHello = try JSONEncoder().encode(
            MatchPacket.hello(.init(playerID: "guest", name: "Guest", rating: 1300, games: 10, deviation: 120))
        )
        host.receive(guestHello)
        #expect(host.phase == .playing)

        // Opponent resigns.
        host.receive(try JSONEncoder().encode(MatchPacket.resign))
        #expect(host.phase == .finished(MatchResult(outcome: .win, reason: .resignation)))

        let applied = try #require(host.applyServerResult(ratingDelta: 174, deviation: 285.5))
        #expect(applied.ratingDelta == 174)
        #expect(applied.deviation == 285.5)
        #expect(host.phase == .finished(applied))

        // Client-side settle after applyServerResult does nothing.
        #expect(host.settle(.new, against: .new) == nil)

        // All server unrated reasons map cleanly, including void.
        #expect(UnratedReason(rawValue: "void") == .void)
        #expect(!UnratedReason.void.text.isEmpty)
    }

    @Test("Wire encoding and decoding for login, events, match/send, leaderboard, invites, and friends")
    func wireContracts() async throws {
        let mock = MockOnlineTransport()
        let api = OnlineAPI(
            transport: mock,
            baseURL: URL(string: "https://chat-api.wonek.com:5433")!,
            device: "device-1234567890abcdef"
        )

        // 1. /login
        await mock.state.enqueue { req in
            #expect(req.method == "POST")
            #expect(req.url.absoluteString == "https://chat-api.wonek.com:5433/brasspawn/v1/login")
            #expect(req.headers["Authorization"] == nil)
            #expect(req.headers["X-Device-ID"] == "device-1234567890abcdef")
            let body = decodeJSON(req.body)
            #expect(body["device"] as? String == "device-1234567890abcdef")
            #expect(body["alias"] as? String == "Mincho")
            let gc = body["gamecenter"] as? [String: Any]
            #expect(gc?["playerID"] as? String == "T:_player1")
            #expect(gc?["bundleID"] as? String == "com.arte-soft.brasspawn")
            return jsonResponse(200, [
                "session": "bp1.tok.sig",
                "expires": 1_790_086_400,
                "account": "0123456789abcdef0123456789abcdef",
                "alias": "Mincho",
                "aliasNeeded": false,
                "records": [
                    "5": ["rating": 1450, "deviation": 95.5, "games": 24, "lastPlayed": 1_790_000_000],
                    "10": ["rating": 1200, "deviation": 350.0, "games": 0, "lastPlayed": 0],
                ],
            ])
        }

        let login = try await api.login(
            alias: "Mincho",
            gameCenter: GameCenterProof(
                playerID: "T:_player1",
                bundleID: "com.arte-soft.brasspawn",
                publicKeyURL: "https://static.gc.apple.com/public-key/gc-prod-10.cer",
                signature: "AA==",
                salt: "BB==",
                timestamp: 1_790_000_000_000
            )
        )
        #expect(login.session == "bp1.tok.sig")
        #expect(login.account == "0123456789abcdef0123456789abcdef")
        #expect(login.records[5]?.rating == 1450)
        #expect(login.records[5]?.games == 24)
        #expect(login.records[10]?.games == 0)
        #expect(login.records[10]?.lastPlayed == nil)

        // 2. /events long-poll
        await mock.state.enqueue { req in
            #expect(req.method == "GET")
            #expect(req.url.absoluteString == "https://chat-api.wonek.com:5433/brasspawn/v1/events?after=0&wait=25")
            #expect(req.headers["Authorization"] == "Bearer bp1.tok.sig")
            #expect(req.timeout > 35)
            return jsonResponse(200, [
                "events": [
                    [
                        "n": 1,
                        "type": "match",
                        "match": "m1",
                        "host": true,
                        "minutes": 5,
                        "open": true,
                        "opponent": ["id": "ffffffffffffffffffffffffffffffff", "alias": "Bot", "rating": 1320, "deviation": 110.0, "games": 12],
                        "me": ["rating": 1450, "deviation": 95.5, "games": 24],
                    ],
                    [
                        "n": 2,
                        "type": "packet",
                        "match": "m1",
                        "packet": ["resign": [String: Any]()],
                    ],
                    [
                        "n": 3,
                        "type": "result",
                        "match": "m1",
                        "game": 1,
                        "winner": "white",
                        "reason": "resignation",
                        "rated": false,
                        "unrated": "void",
                        "minutes": 5,
                        "delta": 0,
                        "record": ["rating": 1450, "deviation": 95.5, "games": 24, "lastPlayed": 1_790_000_000],
                    ],
                    [
                        "n": 4,
                        "type": "invite",
                        "from": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                        "alias": "Ana",
                        "minutes": 10,
                    ],
                ],
                "next": 4,
                "serverTime": 1_790_000_050,
            ])
        }

        let batch = try await api.events(after: 0, waitSeconds: 25)
        #expect(batch.next == 4)
        #expect(batch.events.count == 4)
        if case .matched(let info) = batch.events[0] {
            #expect(info.id == "m1" && info.host && info.opponent.alias == "Bot")
        } else {
            Issue.record("Expected matched event")
        }
        if case .result(let res) = batch.events[2] {
            #expect(!res.rated && res.unratedReason == .void)
        } else {
            Issue.record("Expected result event")
        }
        if case .invited(let inv) = batch.events[3] {
            #expect(inv.id == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && inv.alias == "Ana" && inv.minutes == 10)
        } else {
            Issue.record("Expected invite event")
        }

        // 3. /match/send embeds MatchPacket as a JSON object, not a string
        await mock.state.enqueue { req in
            let body = decodeJSON(req.body)
            #expect(body["match"] as? String == "m1")
            let packetObj = body["packet"] as? [String: Any]
            let moveWrapper = (packetObj?["move"] as? [String: Any])?["_0"] as? [String: Any]
            #expect(moveWrapper?["uci"] as? String == "e2e4")
            #expect(moveWrapper?["ply"] as? Int == 1)
            return jsonResponse(200, ["ok": true])
        }
        let moveData = try JSONEncoder().encode(MatchPacket.move(.init(uci: "e2e4", ply: 1, remaining: 299.1, yours: 300)))
        try await api.send(match: "m1", packet: moveData)

        // 4. /leaderboard
        await mock.state.enqueue { req in
            let body = decodeJSON(req.body)
            #expect(body["minutes"] as? Int == 5)
            #expect(body["scope"] as? String == "around")
            #expect(body["limit"] as? Int == 50)
            return jsonResponse(200, [
                "entries": [
                    ["rank": 1, "id": "0123456789abcdef0123456789abcdef", "alias": "Mincho", "rating": 1450, "deviation": 95.5, "games": 24, "lastPlayed": 1_790_000_000]
                ],
                "me": ["rank": 1, "id": "0123456789abcdef0123456789abcdef", "alias": "Mincho", "rating": 1450, "deviation": 95.5, "games": 24, "lastPlayed": 1_790_000_000],
                "total": 1,
            ])
        }
        let board = try await api.leaderboard(minutes: 5, scope: "around", limit: 50)
        #expect(board.total == 1 && board.entries.first?.rank == 1 && board.me?.alias == "Mincho")

        // 5. /invite/create, /invite/join, /invite/cancel
        await mock.state.enqueue { req in
            #expect(decodeJSON(req.body)["minutes"] as? Int == 10)
            return jsonResponse(200, [
                "code": "K7QM2X",
                "minutes": 10,
                "link": "https://brasspawn.com/play?i=K7QM2X",
                "expires": 1_790_000_600,
            ])
        }
        let created = try await api.createInvite(minutes: 10)
        #expect(created.code == "K7QM2X" && created.link == "https://brasspawn.com/play?i=K7QM2X")

        await mock.state.enqueue { req in
            #expect(decodeJSON(req.body)["code"] as? String == "K7QM2X")
            return jsonResponse(200, ["ok": true, "match": "m2"])
        }
        try await api.joinInvite(code: " k7qm2x ")

        await mock.state.enqueue { _ in jsonResponse(200, ["ok": true]) }
        try await api.cancelInvite()

        // 6. /friends, /friends/request, /friends/accept, /friends/remove, /friends/invite, /friends/answer
        await mock.state.enqueue { _ in
            jsonResponse(200, [
                "friends": [["id": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "alias": "Bo", "since": 100]],
                "incoming": [["id": "cccccccccccccccccccccccccccccccc", "alias": "Cara", "since": 101]],
                "outgoing": [],
                "invites": [["id": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "alias": "Bo", "minutes": 3]],
            ])
        }
        let friends = try await api.friends()
        #expect(friends.friends.count == 1 && friends.incoming.count == 1 && friends.invites.first?.minutes == 3)

        await mock.state.enqueue { req in
            #expect(decodeJSON(req.body)["to"] as? String == "dddddddddddddddddddddddddddddddd")
            return jsonResponse(200, ["status": "asked"])
        }
        try await api.requestFriend(to: "dddddddddddddddddddddddddddddddd")

        await mock.state.enqueue { req in
            #expect(decodeJSON(req.body)["from"] as? String == "cccccccccccccccccccccccccccccccc")
            return jsonResponse(200, ["status": "friends"])
        }
        try await api.acceptFriend(from: "cccccccccccccccccccccccccccccccc")

        await mock.state.enqueue { req in
            let body = decodeJSON(req.body)
            #expect(body["from"] as? String == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
            #expect(body["accept"] as? Bool == true)
            return jsonResponse(200, ["status": "answered", "match": "m3"])
        }
        try await api.answerOffer(from: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", accept: true)

        await mock.state.enqueue { req in
            #expect(decodeJSON(req.body)["other"] as? String == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
            return jsonResponse(200, ["status": "removed"])
        }
        try await api.removeFriend("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    }

    @Test("Automatic 401 re-authentication and strictly ordered outbox retry into MatchSession")
    func reauthAndOrderedOutboxMatchFlow() async throws {
        let mock = MockOnlineTransport()
        let api = OnlineAPI(
            transport: mock,
            baseURL: URL(string: "http://127.0.0.1:8787")!,
            device: "device-test-outbox-0001"
        )
        api.session = "expired-token"

        var reauthCount = 0
        api.reauthenticator = {
            reauthCount += 1
            return try await api.login(
                alias: "HostPlayer",
                gameCenter: GameCenterProof(
                    playerID: "T:test-host",
                    bundleID: "com.arte-soft.brasspawn",
                    publicKeyURL: "https://static.gc.apple.com/public-key/gc-prod-10.cer",
                    signature: "AA==",
                    salt: "AA==",
                    timestamp: 1_790_000_000_001
                )
            )
        }

        // First /seek hits 401 -> triggers /login -> retries /seek with fresh token!
        await mock.state.enqueue { req in
            #expect(req.url.path == "/brasspawn/v1/seek")
            #expect(req.headers["Authorization"] == "Bearer expired-token")
            return jsonResponse(401, ["error": "session"])
        }
        await mock.state.enqueue { req in
            #expect(req.url.path == "/brasspawn/v1/login")
            return jsonResponse(200, [
                "session": "fresh-token",
                "expires": 1_790_086_400,
                "account": "11111111111111111111111111111111",
                "alias": "HostPlayer",
                "aliasNeeded": false,
                "records": [:],
            ])
        }
        await mock.state.enqueue { req in
            #expect(req.url.path == "/brasspawn/v1/seek")
            #expect(req.headers["Authorization"] == "Bearer fresh-token")
            return jsonResponse(200, ["ok": true])
        }

        try await api.seek(minutes: 5)
        #expect(reauthCount == 1)
        #expect(api.session == "fresh-token")

        // Now drive a full match via OnlineMatchDriver with transient outbox failure on packet 1.
        actor SendLog {
            var sentKinds: [String] = []
            var firstHelloFailed = false
            func record(_ kind: String) { sentKinds.append(kind) }
            func shouldFailFirstHello() -> Bool {
                if !firstHelloFailed {
                    firstHelloFailed = true
                    return true
                }
                return false
            }
            func kinds() -> [String] { sentKinds }
        }
        let sendLog = SendLog()

        let customMock = MockOnlineTransport()
        let matchAPI = OnlineAPI(
            transport: customMock,
            baseURL: URL(string: "http://127.0.0.1:8787")!,
            device: "device-test-outbox-0001"
        )
        matchAPI.session = "fresh-token"

        // Enqueue responses for outbox packets:
        // 1st attempt of initial hello -> transient URLError(.networkConnectionLost)
        // 2nd attempt of initial hello -> 200 OK
        // Subsequent packets (hello + start + move) -> 200 OK
        await customMock.state.enqueue { req in
            let packet = decodeJSON(req.body)["packet"] as? [String: Any] ?? [:]
            let kind = packet.keys.first ?? ""
            #expect(kind == "hello")
            if await sendLog.shouldFailFirstHello() {
                throw URLError(.networkConnectionLost)
            }
            await sendLog.record(kind)
            return jsonResponse(200, ["ok": true])
        }
        for _ in 0..<5 {
            await customMock.state.enqueue { req in
                try? await Task.sleep(for: .milliseconds(5))
                let packet = decodeJSON(req.body)["packet"] as? [String: Any] ?? [:]
                let kind = packet.keys.first ?? ""
                await sendLog.record(kind)
                return jsonResponse(200, ["ok": true])
            }
        }

        let matchInfo = OnlineMatchInfo(
            id: "match-42",
            host: true,
            minutes: 5,
            open: true,
            opponent: OnlinePlayer(id: "22222222222222222222222222222222", alias: "GuestBot", record: .new),
            me: .new
        )
        let driver = OnlineMatchDriver(
            info: matchInfo,
            account: "11111111111111111111111111111111",
            alias: "HostPlayer",
            api: matchAPI,
            retryDelay: { _ in .milliseconds(5) }
        )

        driver.begin(whiteIsHost: true)

        // Guest says hello via event stream -> host deals colours & enters .playing.
        let guestHello = try JSONEncoder().encode(
            MatchPacket.hello(.init(playerID: "22222222222222222222222222222222", name: "GuestBot", rating: 1200, games: 0, deviation: 350))
        )
        driver.handle(.packet(match: "match-42", packet: guestHello))
        #expect(driver.session.phase == .playing)
        #expect(driver.session.myColor == .white)

        // Host plays e2e4.
        #expect(driver.session.play(from: Square("e2")!, to: Square("e4")!, promotion: nil))

        // Wait for async outbox to drain.
        for _ in 0..<40 {
            if await sendLog.kinds().count >= 4 { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        let deliveredKinds = await sendLog.kinds()
        #expect(deliveredKinds == ["hello", "hello", "start", "move"])
        #expect(await customMock.state.peakInFlight() == 1, "strictly one packet in flight at a time")

        // Peer disconnect/reconnect & opponent resign + server result.
        driver.handle(.peer(match: "match-42", connected: false))
        #expect(!driver.opponentConnected)
        driver.handle(.peer(match: "match-42", connected: true))
        #expect(driver.opponentConnected)

        driver.handle(.packet(match: "match-42", packet: try JSONEncoder().encode(MatchPacket.resign)))
        let serverRecord = OnlineRecord(rating: 1362, deviation: 290.2, games: 1, lastPlayed: Date(timeIntervalSince1970: 1_790_000_100))
        driver.handle(.result(OnlineGameResult(
            match: "match-42",
            game: 1,
            winner: "white",
            reason: "resignation",
            rated: true,
            unrated: nil,
            minutes: 5,
            delta: 162,
            record: serverRecord
        )))
        #expect(driver.latestResult?.delta == 162)
        if case .finished(let finalResult) = driver.session.phase {
            #expect(finalResult.ratingDelta == 162)
            #expect(finalResult.deviation == 290.2)
        } else {
            Issue.record("Session should be finished with server delta")
        }

        driver.handle(.matchEnded(match: "match-42"))
        #expect(driver.isClosed)
        #expect(driver.session.opponentLeft)
        driver.shutdown()
    }

    @Test("One-off rating carry-over imports only clocks with 0 server games and existing GC rating")
    func oneOffRatingImport() async throws {
        let mock = MockOnlineTransport()
        let api = OnlineAPI(
            transport: mock,
            baseURL: URL(string: "http://127.0.0.1:8787")!,
            device: "device-rating-import-01"
        )
        api.session = "valid-session"

        struct ImportedPayload: Sendable, Equatable {
            let minutes: Int
            let rating: Int
            let games: Int
        }
        actor ImportedClocks {
            var payloads: [ImportedPayload] = []
            func append(_ payload: ImportedPayload) { payloads.append(payload) }
            func all() -> [ImportedPayload] { payloads }
        }
        let importedClocks = ImportedClocks()

        // Expect /rating/import ONLY for 5 min (has GC rating, 0 server games) and 15 min (pre-context GC rating with games=0 -> promoted to 1).
        for _ in 0..<2 {
            await mock.state.enqueue { req in
                #expect(req.url.path == "/brasspawn/v1/rating/import")
                let body = decodeJSON(req.body)
                let minutes = body["minutes"] as? Int ?? 0
                let rating = body["rating"] as? Int ?? 1200
                let games = body["games"] as? Int ?? 1
                let deviation = body["deviation"] as? Double ?? 350.0
                let lastPlayed = body["lastPlayed"] as? Int ?? 0
                await importedClocks.append(ImportedPayload(minutes: minutes, rating: rating, games: games))
                return jsonResponse(200, [
                    "record": [
                        "rating": rating,
                        "deviation": deviation,
                        "games": games,
                        "lastPlayed": lastPlayed,
                    ]
                ])
            }
        }

        let serverRecords: [Int: OnlineRecord] = [
            3: .new, // 0 server games, nil GC -> do NOT import
            5: .new, // 0 server games, GC 1540 (32 games) -> IMPORT
            10: OnlineRecord(rating: 1610, deviation: 80, games: 15, lastPlayed: Date(timeIntervalSince1970: 1_790_000_000)), // already has server games -> do NOT overwrite!
            15: .new, // 0 server games, legacy GC 1410 (0 context games) -> IMPORT with games=1
            30: .new,
        ]

        let merged = await OnlineAPI.importRatingsIfNeeded(serverRecords: serverRecords, api: api) { control in
            switch control {
            case .five:
                return OnlineRecord(rating: 1540, deviation: 90, games: 32, lastPlayed: Date(timeIntervalSince1970: 1_789_000_000))
            case .ten:
                return OnlineRecord(rating: 1999, deviation: 60, games: 99, lastPlayed: Date(timeIntervalSince1970: 1_789_000_000))
            case .fifteen:
                return OnlineRecord(rating: 1410, deviation: 350, games: 0, lastPlayed: nil)
            default:
                return nil
            }
        }

        let sent = await importedClocks.all()
        #expect(sent.count == 2)
        #expect(sent[0] == ImportedPayload(minutes: 5, rating: 1540, games: 32))
        #expect(sent[1] == ImportedPayload(minutes: 15, rating: 1410, games: 1))
        #expect(merged[5]?.rating == 1540)
        #expect(merged[10]?.rating == 1610, "existing server record was preserved")
        #expect(merged[15]?.rating == 1410 && merged[15]?.games == 1)
        #expect(merged[3]?.games == 0)
    }

    @Test("Service invite URL parsing handles brasspawn.com and custom scheme without breaking App Clip links")
    func inviteURLParsing() {
        #expect(Invitation.inviteCode(in: URL(string: "https://brasspawn.com/play?i=K7QM2X")!) == "K7QM2X")
        #expect(Invitation.inviteCode(in: URL(string: "https://www.brasspawn.com/play?i=k7qm2x")!) == "K7QM2X")
        #expect(Invitation.inviteCode(in: URL(string: "brasspawn://play?i=ab23cd")!) == "AB23CD")
        #expect(Invitation.inviteCode(in: URL(string: "brasspawn://play/9XYZ23")!) == "9XYZ23")

        // Rejects non-6-char or non-play URLs.
        #expect(Invitation.inviteCode(in: URL(string: "https://brasspawn.com/play?i=SHORT")!) == nil)
        #expect(Invitation.inviteCode(in: URL(string: "https://brasspawn.com/play?i=TOOLONG7")!) == nil)
        #expect(Invitation.inviteCode(in: URL(string: "https://brasspawn.com/today/some-story")!) == nil)
        #expect(Invitation(url: URL(string: "https://brasspawn.com/play?i=K7QM2X")!) == nil)

        // Legacy App Clip base64 JSON invitation still parses as Invitation and NOT as a 6-char code.
        let legacy = Invitation(name: "Mincho", playerID: "G:12345", minutes: 5)
        #expect(Invitation.inviteCode(in: legacy.link) == nil)
        #expect(Invitation(url: legacy.link) == legacy)
    }
}

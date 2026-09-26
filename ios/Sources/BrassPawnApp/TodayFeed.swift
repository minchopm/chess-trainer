import ChessTraining
import Foundation
import Observation

/// Today's stories, and the one request the app makes to a server of ours.
///
/// It is made when the Today screen is opened and at no other time: not at
/// launch, not in the background, not to check for anything. What goes out is
/// a plain GET for a static file — no account, no identifier, no cookie, no
/// cache the next request could be matched against — and the file is the same
/// for everybody who asks. brasspawn.com keeps no log of it. PRIVACY.md says
/// the same, and App Review has been told.
///
/// The last copy that arrived is kept on disk, so a reader on a train sees
/// yesterday's stories rather than an error, and a second visit in the same
/// ten minutes does not ask again.
@Observable
@MainActor
final class TodayFeed {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        /// Could not reach the feed. Whatever was on disk is still shown.
        case failed
    }

    static let address: URL = {
        #if DEBUG
        // A debug build can be pointed at a preview of unapproved drafts —
        // `node scripts/feed/publish.mjs --preview`, served locally. A release
        // build cannot: the override does not exist in it.
        if let override = ProcessInfo.processInfo.environment["BRASSPAWN_FEED_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://brasspawn.com/media/feed/v1/latest.json")!
    }()

    private(set) var stories: [FeedStory] = []
    private(set) var state = State.idle
    /// When the copy on screen was written by the feed, not when it was fetched.
    private(set) var generatedAt: Date?
    /// Every day the feed has, newest first.
    private(set) var days: [FeedFile.Day] = []
    /// The earlier days read so far, beyond the newest few in the first file.
    private var earlier: [String: [FeedStory]] = [:]
    private(set) var isLoadingEarlier = false

    /// Days listed but not yet read, oldest last.
    var unreadDays: [FeedFile.Day] {
        let shown = Set(stories.map(\.date))
        return days.filter { !shown.contains($0.date) }
    }

    private var fetchedAt: Date?
    private var readDisk = false

    /// A session that remembers nothing between requests.
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    private static var cacheFile: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("today-feed-v1.json")
    }

    /// Show what is on disk, then ask for what is new — unless it was asked
    /// for a moment ago.
    func refresh(force: Bool = false) async {
        if !readDisk {
            readDisk = true
            if let file = Self.cacheFile, let data = try? Data(contentsOf: file),
               let feed = try? await Self.decoded(data) {
                show(feed)
            }
        }
        if !force, let fetchedAt, Date().timeIntervalSince(fetchedAt) < 600 { return }
        guard state != .loading else { return }

        state = .loading
        do {
            var request = URLRequest(url: Self.address)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let feed = try await Self.decoded(data)
            show(feed)
            fetchedAt = Date()
            state = .loaded
            if let file = Self.cacheFile { try? data.write(to: file, options: .atomic) }
        } catch {
            state = .failed
        }
    }

    /// Off the main thread: reading a file checks every move of every game in
    /// it, which is a few hundred positions a story — a scroll's worth of
    /// stutter if the interface waited for it.
    private static func decoded(_ data: Data) async throws -> FeedFile {
        try await Task.detached(priority: .userInitiated) { try FeedFile.decode(data) }.value
    }

    func story(id: String) -> FeedStory? {
        stories.first { $0.id == id }
    }

    /// The next few days back, a file each. Called as the reader reaches the
    /// foot of the list, so the history costs nothing to somebody who only
    /// wants today.
    func loadEarlier(days count: Int = 3) async {
        guard !isLoadingEarlier else { return }
        let next = unreadDays.prefix(count)
        guard !next.isEmpty else { return }
        isLoadingEarlier = true
        defer { isLoadingEarlier = false }
        let base = Self.address.deletingLastPathComponent().appendingPathComponent("days")
        for day in next {
            do {
                let (data, response) = try await session.data(from: base.appendingPathComponent("\(day.date).json"))
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                earlier[day.date] = try await Task.detached(priority: .userInitiated) {
                    try FeedDay.decode(data).stories
                }.value
            } catch {
                // An empty day rather than a stuck one: the list moves on to
                // the day before, and the next refresh may bring it back.
                earlier[day.date] = []
                days.removeAll { $0.date == day.date }
            }
        }
        rebuild()
    }

    /// The first file's stories — the newest days.
    private var newest: [FeedStory] = []

    private func show(_ feed: FeedFile) {
        generatedAt = feed.generatedAt
        days = feed.days ?? []
        newest = feed.stories
        rebuild()
    }

    /// The newest days and whatever earlier days have been read, newest first.
    private func rebuild() {
        let dates = Set(newest.map(\.date))
        let back = earlier
            .filter { !dates.contains($0.key) }
            .sorted { $0.key > $1.key }
            .flatMap(\.value)
        stories = newest + back
    }
}

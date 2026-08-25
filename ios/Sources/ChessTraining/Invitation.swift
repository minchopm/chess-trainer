import Foundation

/// One person asking another for a game.
///
/// The link is the whole of it. There is no server to register an invitation
/// with, so everything the other end needs travels inside the URL: who sent it,
/// and which Game Center player to look for. That is also why it is signed by
/// nothing — an invitation is not a credential, and the worst a forged one can
/// do is name somebody who then declines.
public struct Invitation: Codable, Hashable, Sendable {
    /// What the inviter is called. Their Game Center alias, which is the name
    /// they would see over the board anyway.
    public let name: String
    /// The inviter's Game Center player ID, so the app can go straight to them
    /// rather than into the general queue.
    public let playerID: String
    /// Minutes on the clock, so both sides start the game they agreed to.
    public let minutes: Int

    public init(name: String, playerID: String, minutes: Int) {
        self.name = name
        self.playerID = playerID
        self.minutes = minutes
    }
}

public extension Invitation {
    /// The pool the two of them meet in.
    ///
    /// Game Center will not hand you a named opponent — it hands you whoever is
    /// waiting in the same `playerGroup`. The ordinary groups are the five
    /// clocks, which is why an invitation cannot simply join one: it would find
    /// a stranger. So an invitation derives a group of its own from the
    /// inviter's player ID, a number nobody else will land on, and both ends
    /// compute it the same way from the same link. Two people, one pool.
    ///
    /// Deliberately not `Hasher`: Swift seeds that per process, so the two
    /// devices would compute different numbers for the same invitation.
    var playerGroup: Int {
        var hash: UInt32 = 2_166_136_261
        for byte in Array("\(playerID)#\(minutes)".utf8) {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        // Above the five clock groups, and inside the range Game Center takes.
        return 100_000 + Int(hash % 1_000_000)
    }

    /// The App Clip's invocation URL.
    ///
    /// `appclip.apple.com` rather than a domain of ours: it needs no site, no
    /// association file and no hosting, and it is the one form of the link that
    /// works the moment the clip is approved. Sent through whatever the sender
    /// already uses — Messages, WhatsApp, mail — because it is only a link.
    static let clipBundleID = "com.arte-soft.brasspawn.Clip"

    var link: URL {
        var components = URLComponents(string: "https://appclip.apple.com/id")!
        components.queryItems = [
            URLQueryItem(name: "p", value: Self.clipBundleID),
            URLQueryItem(name: "i", value: encoded),
        ]
        return components.url!
    }

    /// Base64, URL-safe and unpadded, so the whole invitation survives being
    /// pasted into a chat window and typed back out by hand at the other end.
    var encoded: String {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(encoded: String) {
        var text = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while text.count % 4 != 0 { text += "=" }
        guard let data = Data(base64Encoded: text),
              let decoded = try? JSONDecoder().decode(Invitation.self, from: data)
        else { return nil }
        self = decoded
    }

    /// Pull an invitation out of whatever URL launched us — the clip's
    /// invocation URL, or a universal link into the full app.
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "i" })?.value,
              let invitation = Invitation(encoded: code)
        else { return nil }
        self = invitation
    }
}

/// The one thing the App Clip leaves behind for the app to find.
///
/// A clip and the app it belongs to are separate installs with separate
/// containers; the App Group is the only ground they both stand on. Somebody
/// who follows an invitation, plays a puzzle or two in the clip and then
/// installs the app should not have to be sent the link a second time, so the
/// clip writes the invitation here and the app reads it once on first launch.
public enum SharedContainer {
    public static let appGroup = "group.com.arte-soft.brasspawn"

    private static var directory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    private static var pendingInvitation: URL? {
        directory?.appending(path: "pending-invitation.json")
    }

    /// Written by the clip. Overwrites any earlier one: the most recent
    /// invitation is the one being acted on.
    public static func store(_ invitation: Invitation) {
        guard let url = pendingInvitation,
              let data = try? JSONEncoder().encode(invitation)
        else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Read by the app, once. Taking it away as it is read is deliberate: an
    /// invitation that survived being declined would be offered again at every
    /// launch, which is a nag rather than a courtesy.
    public static func takeInvitation() -> Invitation? {
        guard let url = pendingInvitation,
              let data = try? Data(contentsOf: url),
              let invitation = try? JSONDecoder().decode(Invitation.self, from: data)
        else { return nil }
        try? FileManager.default.removeItem(at: url)
        return invitation
    }
}

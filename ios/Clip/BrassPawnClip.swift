import GameKit
import SwiftUI

/// The smallest App Clip that can answer one question.
///
/// Does Game Center treat an App Clip as the same game as the app it belongs
/// to? The clip has its own bundle identifier, and Game Center matches players
/// "playing the same game" — if it keys that on the bundle, somebody invited
/// into the clip can never join the person who invited them, and the whole
/// idea of inviting people who do not have the app collapses.
///
/// Apple's documentation does not say. Multiplayer Compatibility in App Store
/// Connect pairs *separate apps* with different bundle identifiers, but an App
/// Clip has no app record of its own — it shares the parent's. So this is here
/// to find out by trying, before anything is built on top of the answer.
/// Carries a non-Sendable Game Center object from its callback to the main
/// actor. The same box the app uses, for the same reason: nothing else touches
/// it in between.
private final class UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

@main
struct BrassPawnClip: App {
    var body: some Scene {
        WindowGroup { SpikeView() }
    }
}

@MainActor
@Observable
final class Spike: NSObject {
    var lines: [String] = []
    private var match: GKMatch?

    func say(_ line: String) {
        lines.append(line)
    }

    func authenticate() {
        say("Authenticating…")
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.say("Refused: \(error.localizedDescription)")
                    return
                }
                if controller != nil {
                    self.say("Game Center wants its sign-in screen — not shown here.")
                    return
                }
                guard GKLocalPlayer.local.isAuthenticated else {
                    self.say("Not authenticated, and no reason given.")
                    return
                }
                self.say("Signed in as \(GKLocalPlayer.local.alias)")
                self.say("gamePlayerID \(GKLocalPlayer.local.gamePlayerID)")
                self.findMatch()
            }
        }
    }

    /// Ask for the same match the full app asks for. If Game Center puts the
    /// two together, the answer is yes.
    private func findMatch() {
        say("Looking for a two-player match…")
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            let carried = UncheckedBox(match)
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.say("No match: \(error.localizedDescription)")
                    return
                }
                guard let match = carried.value else {
                    self.say("No match, and no error either.")
                    return
                }
                self.match = match
                let names = match.players.map(\.alias).joined(separator: ", ")
                self.say("MATCHED with \(match.players.count): \(names)")
            }
        }
    }
}

private struct SpikeView: View {
    @State private var spike = Spike()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Brass Pawn").font(.largeTitle)
            Text("App Clip · Game Center spike").font(.caption).foregroundStyle(.secondary)
            Divider()
            ForEach(Array(spike.lines.enumerated()), id: \.offset) { _, line in
                Text(line).font(.system(.footnote, design: .monospaced))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { spike.authenticate() }
    }
}

import ChessCore
import ChessTraining
import SwiftUI

/// Playing a stranger over Game Center.
///
/// The one mode with no engine in it. Nothing here suggests a move, grades one,
/// or puts a number on a square: an opponent is on the other end, and help that
/// only one side gets is not a game.
struct OnlineScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivityGuard.self) private var activity
    private var matchmaker: GameCenterMatchmaker { app.matchmaker }
    @State private var timeControl = TimeControl.five
    @State private var settled: MatchResult?
    /// Left by the App Clip, if somebody arrived here from a link. Read
    /// once and taken away, so a declined invitation is not offered again.
    @State private var invitation: Invitation?

    /// Drives the clock display. The clock itself works from timestamps, so
    /// this only decides how often the numbers are redrawn — not how they are
    /// counted. The instant it hands the matchmaker is the one every clock on
    /// screen reads from.
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let session = matchmaker.session {
                game(session)
            } else {
                lobby
            }
        }
        .onReceive(ticker) { instant in
            matchmaker.tick(now: instant)
            settleIfFinished()
        }
        .onAppear {
            if case .signedOut = matchmaker.state { matchmaker.authenticate() }
            if invitation == nil, let waiting = SharedContainer.takeInvitation() {
                invitation = waiting
                timeControl = TimeControl(rawValue: waiting.minutes) ?? .five
            }
        }
        .onDisappear {
            matchmaker.cancelSearch()
            activity.release()
        }
        #if canImport(UIKit)
        .fullScreenCover(item: Binding(
            get: { matchmaker.pendingAuthController },
            set: { matchmaker.pendingAuthController = $0 }
        )) { item in
            HostedController(controller: item.controller)
        }
        #endif
    }

    // MARK: - Lobby

    private var lobby: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    Text(L.t("online.playOnline", "Play online")).appFont(size: 22, weight: .semibold)
                    Text(L.t("online.aRealOpponentOverGame", "A real opponent over Game Center, on the clock. No hints, no engine, no take-backs."))
                        .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                }

                if let invitation {
                    invitationCard(invitation)
                }

                Card {
                    Text(L.t("online.clock", "Clock")).appFont(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                    BrassSegmentedPicker(
                        L.t("online.clock", "Clock"),
                        selection: $timeControl,
                        options: Array(TimeControl.allCases)
                    ) { control in
                        Text(verbatim: "\(control.minutes)")
                    }
                    .disabled(isSearching)
                    Text(L.t("online.clockExplanation", "%@ each — %@. You are only paired with players who chose the same clock.", timeControl.label, timeControl.name.lowercased()))
                        .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                }

                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(matchmaker.localName).appFont(.subheadline, weight: .semibold)
                            Text(verbatim: "\(app.progress.rating(.online(minutes: timeControl.minutes)))")
                                .appFont(size: 22, weight: .semibold).monospacedDigit()
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L.t("online.record", "Record")).appFont(.caption2).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                            Text(verbatim: "\(app.progress.onlineWins)–\(app.progress.onlineLosses)–\(app.progress.onlineDraws)")
                                .appFont(.subheadline).monospacedDigit().foregroundStyle(Theatre.ivoryDim)
                        }
                    }
                    Text(matchmaker.status).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                }

                if isSearching {
                    Button(role: .destructive) { matchmaker.cancelSearch() } label: {
                        HStack(spacing: 8) {
                            BrassActivityIndicator(size: 15)
                            Text(L.t("online.searchingTapToCancel", "Searching — tap to cancel"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .danger))
                } else {
                    Button {
                        matchmaker.findOpponent(
                            timeControl: timeControl,
                            rating: app.progress.rating(.online(minutes: timeControl.minutes)),
                            games: app.progress.gamesPlayed(.online(minutes: timeControl.minutes))
                        )
                    } label: {
                        Text(matchmaker.isAuthenticated ? "Find opponent" : "Sign in to Game Center")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .solid))
                }

                inviteCard
            }
            .padding(12)
        }
    }

    // MARK: - Invitations

    /// Somebody arrived here from a link and their invitation survived the
    /// install. Accepting it searches that invitation's own pool, so the
    /// opponent found is the person who sent it and nobody else.
    @ViewBuilder
    private func invitationCard(_ invitation: Invitation) -> some View {
        Card {
            Slug(text: L.t("online.invitation", "Invitation"))
            Text(L.t("clip.invitedYou", "%@ invited you to a game.", invitation.name))
                .appFont(.subheadline)
            Text(L.t(
                "online.invitationClock",
                "%@ each. You will be put straight through to them rather than into the general pool.",
                TimeControl(rawValue: invitation.minutes)?.label ?? "\(invitation.minutes)"
            ))
            .appFont(.footnote)
            .foregroundStyle(Theatre.ivoryDim)
            HStack(spacing: 10) {
                Button(L.t("online.accept", "Accept")) {
                    let control = TimeControl(rawValue: invitation.minutes) ?? .five
                    timeControl = control
                    matchmaker.findOpponent(
                        timeControl: control,
                        rating: app.progress.rating(.online(minutes: control.minutes)),
                        games: app.progress.gamesPlayed(.online(minutes: control.minutes)),
                        invitation: invitation
                    )
                }
                .buttonStyle(PillButtonStyle(emphasis: .solid))
                .disabled(isSearching || !matchmaker.isAuthenticated)

                Button(L.t("online.decline", "Decline")) { self.invitation = nil }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost))
            }
        }
    }

    /// Asking somebody else. The link opens an App Clip for anybody without the
    /// app — they play a few tactics while it downloads, and the invitation is
    /// waiting for them here afterwards.
    @ViewBuilder
    private var inviteCard: some View {
        if matchmaker.canInvite {
            let mine = Invitation(
                name: matchmaker.localName,
                playerID: matchmaker.localPlayerID,
                minutes: timeControl.minutes
            )
            Card {
                Slug(text: L.t("online.inviteSomebody", "Invite somebody"))
                Text(L.t(
                    "online.inviteExplanation",
                    "Send a link. Whoever opens it can play a few tactics straight away, with or without the app, and the invitation waits for them here."
                ))
                .appFont(.footnote)
                .foregroundStyle(Theatre.ivoryDim)
                ShareLink(
                    item: mine.link,
                    subject: Text(verbatim: "Brass Pawn"),
                    message: Text(L.t(
                        "online.inviteMessage",
                        "A game of chess, %@ each: %@",
                        timeControl.label,
                        mine.link.absoluteString
                    ))
                ) {
                    Text(L.t("online.sendTheLink", "Send the link"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost))
                .disabled(isSearching)
            }
        }
    }

    private var isSearching: Bool {
        if case .searching = matchmaker.state { return true }
        return false
    }

    // MARK: - The game

    private func game(_ session: MatchSession) -> some View {
        TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: session.opponent?.name ?? "Opponent",
                    rating: session.opponent?.rating,
                    color: session.myColor.opponent,
                    material: MaterialBalance(session.position)
                ),
                bottom: PlayerBar(
                    name: matchmaker.localName,
                    rating: app.progress.rating(.online(minutes: timeControl.minutes)),
                    color: session.myColor,
                    material: MaterialBalance(session.position)
                )
            ) {
                GameBoard(
                    position: session.position,
                    orientation: session.myColor,
                    legalDestinations: session.legalDestinations,
                    lastMove: session.lastMove,
                    onMove: { from, to, promotion in
                        session.play(from: from, to: to, promotion: promotion)
                    }
                )
            }
        } panel: {
            statusCard(session)
            Card {
                Text(L.t("online.moves", "Moves")).appFont(.caption).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                MoveList(moves: session.moves.map { (san: $0, grade: nil) })
            }
        } controls: {
            controls(session)
        }
        .fullScreenCover(isPresented: completionIsPresented(session)) {
            if case .finished(let result) = session.phase {
                CompletionOverlay(
                    result: completion(for: settled ?? result),
                    primaryTitle: L.t("online.backToTheLobby", "Back to the lobby"),
                    onPrimary: { matchmaker.leaveMatch(); settled = nil },
                    onRetry: nil
                )
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: session.moves.count) { _, _ in
            SoundBoard.shared.play(.move)
        }
        .onAppear { if isPlaying(session) { holdWhilePlaying() } }
        .onChange(of: isPlaying(session)) { _, playing in
            if playing {
                activity.hold(
                    title: L.t("online.leaveTheGame", "Leave the game?"),
                    reason: L.t("online.leavingAnOnlineGameLoses", "Leaving an online game loses it and costs you rating.")
                )
            } else {
                activity.release()
            }
        }
        .animation(.spring(duration: 0.35), value: settled)
    }

    private func completionIsPresented(_ session: MatchSession) -> Binding<Bool> {
        Binding(
            get: {
                if case .finished = session.phase { return true }
                return false
            },
            set: { _ in }
        )
    }

    private func statusCard(_ session: MatchSession) -> some View {
        Card {
            Text(statusText(session)).appFont(size: 22, weight: .semibold)
            Text(L.t("online.gameSummary", "%@ · %@ · you are %@", session.timeControl.label, session.timeControl.name, L.color(session.myColor)))
                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)

            if session.drawOffered {
                HStack(spacing: 10) {
                    Text(L.t("online.drawOffered", "Draw offered.")).appFont(.subheadline)
                    Button(L.t("online.accept", "Accept")) { session.respondToDraw(accept: true) }
                        .buttonStyle(PillButtonStyle(emphasis: .solid))
                    Button(L.t("online.decline", "Decline")) { session.respondToDraw(accept: false) }
                        .buttonStyle(PillButtonStyle(emphasis: .ghost))
                }
            } else if session.drawOfferSent {
                Text(L.t("online.drawOfferedWaitingForAn", "Draw offered — waiting for an answer."))
                    .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }
        }
    }

    private func statusText(_ session: MatchSession) -> String {
        switch session.phase {
        case .waiting: "Connecting…"
        case .playing: session.isMyTurn ? "Your move." : "Opponent to move."
        case .finished(let result): result.headline
        }
    }

    private func controls(_ session: MatchSession) -> some View {
        ActionBar(items: isPlaying(session)
            ? [
                ActionItem(title: L.t("online.resign", "Resign"), systemImage: "flag.fill", emphasis: .destructive) {
                    session.resign()
                },
                ActionItem(title: L.t("online.offerDraw", "Offer draw"), systemImage: "equal.circle",
                           isEnabled: !session.drawOfferSent) {
                    session.offerDraw()
                },
            ]
            : [
                ActionItem(title: L.t("online.lobby", "Lobby"), systemImage: "chevron.backward", emphasis: .primary) {
                    matchmaker.leaveMatch()
                    settled = nil
                },
            ]
        )
    }

    private func holdWhilePlaying() {
        activity.hold(
            title: L.t("online.leaveTheGame", "Leave the game?"),
            reason: L.t("online.leavingAnOnlineGameLoses", "Leaving an online game loses it and costs you rating.")
        )
    }

    private func isPlaying(_ session: MatchSession) -> Bool {
        if case .playing = session.phase { return true }
        return false
    }

    /// Apply the rating exactly once, the moment the game ends.
    private func settleIfFinished() {
        guard let session = matchmaker.session, settled == nil,
              case .finished = session.phase else { return }
        guard let result = session.settle(
            rating: app.progress.rating(.online(minutes: timeControl.minutes)),
            games: app.progress.gamesPlayed(.online(minutes: timeControl.minutes))
        ) else { return }
        settled = result
        app.update { $0.record(online: result, at: timeControl) }
        activity.release()
        matchmaker.onMatchFinished?(result)
    }

    private func completion(for result: MatchResult) -> CompletionResult {
        let verdict: CompletionResult.Verdict = switch result.outcome {
        case .win: .success
        case .draw: .partial
        case .loss: .failure
        }
        return CompletionResult(
            verdict: verdict,
            title: result.headline,
            detail: result.ratingDelta == 0
                ? nil
                : "Rating \(result.ratingDelta > 0 ? "+" : "")\(result.ratingDelta) → \(app.progress.rating(.online(minutes: timeControl.minutes)))",
            line: nil
        )
    }
}

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
            #if DEBUG
            stageDrawOfferForScreenshot()
            #endif
        }
        .onDisappear {
            matchmaker.cancelSearch()
            activity.release()
        }
        #if canImport(UIKit)
        .appCover(item: Binding(
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

    #if DEBUG
    /// Put a game with a draw on the table on screen, for `.onlineDraw`.
    ///
    /// Against the debug loopback, which exists because Game Center will not
    /// sign in on a simulator. The pause is the opponent thinking: an offer
    /// that is there before the board is reads as part of the furniture.
    private func stageDrawOfferForScreenshot() {
        guard ScreenshotScene.requested == .onlineDraw, matchmaker.session == nil else { return }
        matchmaker.startLoopbackMatch(
            timeControl: timeControl,
            rating: app.progress.rating(.online(minutes: timeControl.minutes)),
            games: 0
        )
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            matchmaker.offerDrawFromLoopback()
        }
    }
    #endif

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
        .appCover(isPresented: completionIsPresented(session)) {
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
        // A draw offer is a question with two answers and a clock running on
        // both of them. It used to be a row inside the status card — under the
        // board on a phone, in the column beside it on a Mac, in both cases
        // somewhere you find by looking, and on the Mac it was simply missed
        // while the game went on.
        //
        // Then it was the app's usual confirmation, which is centred over a
        // dimmed screen and takes a tap anywhere as a refusal. That is the
        // right shape for "leave the game?" and the wrong one here: the clock
        // is still running, the board is still the thing being looked at, and a
        // stray click should not answer for you. So it stands aside instead —
        // no veil, nothing to dismiss by accident, and the board still playable
        // underneath while you decide.
        .overlay { drawOffer(session) }
        .animation(.easeOut(duration: 0.2), value: session.drawOffered)
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

    /// The offer, out of the way.
    ///
    /// It goes at the head of the reading column, on the right, wherever that
    /// column happens to be: beside the board on a wide screen, under it on a
    /// tall one. So on a Mac it is the top-right corner, and on a phone it is
    /// just below the board — in both cases over text rather than over the
    /// position, and clear of the controls, which have to stay pressable.
    ///
    /// The drop in the tall case is the board's own height, taken from the
    /// layout that draws it rather than guessed, so the two cannot disagree.
    @ViewBuilder
    private func drawOffer(_ session: MatchSession) -> some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height
            let board = TrainingLayout<EmptyView, EmptyView, EmptyView>
                .portraitBoard(in: geometry.size) + BoardStage<EmptyView>.chromeHeight
            if session.drawOffered {
                BrassModalPanel(tint: Theatre.brass) {
                    Text(L.t("online.drawOffered", "Draw offered."))
                        .appFont(size: 17, weight: .semibold)
                        .foregroundStyle(Theatre.ivory)
                    Text(L.t("online.offersADraw", "%@ offers a draw.",
                             session.opponent?.name ?? L.t("online.opponent", "Opponent")))
                        .appFont(.footnote)
                        .foregroundStyle(Theatre.ivoryDim)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button(L.t("online.accept", "Accept")) {
                            session.respondToDraw(accept: true)
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .solid))
                        Button(L.t("online.playOn", "Play on")) {
                            session.respondToDraw(accept: false)
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .ghost))
                    }
                }
                // Narrow enough to be a note rather than a screen, and wide
                // enough for two buttons and a name.
                //
                // Only the plate itself takes taps — the reader around it draws
                // nothing, so the board underneath stays playable while you
                // decide. The clock does not stop for a question and neither
                // should the position.
                .frame(maxWidth: 270)
                .padding(12)
                .padding(.top, isWide ? 0 : board)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .frame(
                    width: geometry.size.width, height: geometry.size.height,
                    alignment: .topTrailing
                )
            }
        }
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

            // The offer itself is a modal, not a row in this card — see the
            // overlay on `game`. What stays here is the half that is only news:
            // that your own offer is out and unanswered.
            if session.drawOfferSent {
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

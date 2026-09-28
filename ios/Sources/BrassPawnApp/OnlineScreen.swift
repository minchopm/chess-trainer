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
    /// Whether the game on the board counts for the rating, decided once as
    /// it begins — see `decideRating`.
    @State private var ratingCall: RatingCall?
    /// Left by the App Clip, if somebody arrived here from a link. Read
    /// once and taken away, so a declined invitation is not offered again.
    @State private var invitation: Invitation?
    @State private var showsPlayers = false

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
            // Signed in quietly at launch; asked again here if that did not
            // work, now that somebody has come to play.
            switch matchmaker.state {
            case .signedOut, .failed: matchmaker.authenticate()
            default: break
            }
            if invitation == nil, let waiting = SharedContainer.takeInvitation() {
                invitation = waiting
                timeControl = TimeControl(rawValue: waiting.minutes) ?? .five
            }
            #if DEBUG
            stageDrawOfferForScreenshot()
            stagePlayersForScreenshot()
            #endif
        }
        .task(id: timeControl) { await app.boards.refreshLooking() }
        .appCover(isPresented: $showsPlayers) {
            PlayersScreen(clock: timeControl) { player, control in invite(player, on: control) }
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
                    LookingNow(count: app.boards.lookingNow[timeControl], control: timeControl)
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
                            if let invitee = matchmaker.invitee {
                                Text(L.t("online.waitingForTapToCancel", "Waiting for %@ — tap to cancel", invitee))
                            } else {
                                Text(L.t("online.searchingTapToCancel", "Searching — tap to cancel"))
                            }
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
                        Text(matchmaker.isAuthenticated
                             ? L.t("online.findOpponent", "Find opponent")
                             : L.t("online.signIn", "Sign in to Game Center"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .solid))
                }

                playersCard
                inviteCard
            }
            .padding(12)
        }
    }

    // MARK: - Players

    /// Who to play: the people played lately, then whoever has been about this
    /// week — each an invitation away — and the way to the rank list.
    @ViewBuilder
    private var playersCard: some View {
        if matchmaker.canInvite || app.boards.hasLoaded {
            let boards = app.boards
            let recent = Array(boards.recent.prefix(2))
            let active = Array(boards.active().filter { player in !recent.contains { $0.id == player.id } }
                .prefix(4 - recent.count))
            Card {
                Slug(text: L.t("online.players", "Players"))
                if !boards.hasLoaded {
                    HStack(spacing: 9) {
                        BrassActivityIndicator(size: 15)
                        Text(L.t("online.loadingPlayers", "Reading the lists from Game Center…"))
                            .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                } else if recent.isEmpty && active.isEmpty {
                    Text(L.t("online.nobodyYet", "Nobody else has played online yet. Invite somebody with a link from the lobby."))
                        .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                } else {
                    VStack(spacing: 2) {
                        ForEach(recent + active) { player in
                            PlayerRow(player: player, showsRank: false,
                                      invite: isSearching || matchmaker.session != nil ? nil : { invite(player, on: timeControl) })
                        }
                    }
                }
                Button { showsPlayers = true } label: {
                    Text(L.t("online.rankListAndPlayers", "Rank list and all players"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(emphasis: .ghost))
            }
        }
    }

    /// Invite one player, on a clock — through Game Center, as a notification
    /// on their devices; the lobby shows it going out, and a yes starts the game.
    private func invite(_ player: BoardPlayer, on control: TimeControl) {
        timeControl = control
        matchmaker.invite(player, on: control, from: app.boards)
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
    /// Players to look at, for `.onlineLobby` and `.players`; and a game lost,
    /// with the opponent asking for another, for `.onlineRematch`.
    private func stagePlayersForScreenshot() {
        switch ScreenshotScene.requested {
        case .onlineLobby:
            app.boards.fillWithSamples()
        case .players:
            app.boards.fillWithSamples()
            showsPlayers = true
        case .onlineRematch:
            guard matchmaker.session == nil else { return }
            matchmaker.startLoopbackMatch(timeControl: timeControl,
                                          rating: app.progress.rating(.online(minutes: timeControl.minutes)),
                                          games: 3)
            Task { @MainActor in
                // Once both sides of the loopback are playing.
                while !(matchmaker.session.map(isPlaying) ?? false) {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                try? await Task.sleep(for: .seconds(1.5))
                matchmaker.resignAndAskForRematchFromLoopback()
            }
        default:
            break
        }
    }

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
                    rating: app.progress.rating(.online(minutes: session.timeControl.minutes)),
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
        } notice: {
            drawOffer(session)
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
                    result: completion(for: settled ?? result, at: session.timeControl, unrated: unratedReason(session)),
                    primaryTitle: L.t("online.backToTheLobby", "Back to the lobby"),
                    onPrimary: { matchmaker.leaveMatch(); settled = nil; ratingCall = nil },
                    onRetry: nil,
                    accessory: AnyView(RematchPanel(session: session, hello: { hello(for: session) })),
                    primaryEmphasis: session.opponentLeft || session.rematchDeclined ? .solid : .ghost
                )
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
            }
        }
        .animation(.easeOut(duration: 0.2), value: session.drawOffered)
        // A rematch is a new game in the same match: its result is its own.
        .onChange(of: session.gameNumber) { _, _ in settled = nil }
        .onChange(of: session.moves.count) { _, _ in
            SoundBoard.shared.play(.move)
        }
        .onAppear {
            if isPlaying(session) {
                decideRating(session)
                holdWhilePlaying(session)
            }
        }
        .onChange(of: isPlaying(session)) { _, playing in
            if playing {
                decideRating(session)
                holdWhilePlaying(session)
            } else {
                activity.release()
            }
        }
        .animation(.spring(duration: 0.35), value: settled)
    }

    /// The offer, at the head of the reading and never over it.
    ///
    /// It has been three things. A row inside the status card — under the board
    /// on a phone, in the column beside it on a Mac, in both cases somewhere
    /// you find by looking, and on the Mac it was simply missed while the game
    /// went on. Then the app's usual confirmation, centred over a dimmed
    /// screen, which takes a tap anywhere as a refusal: the right shape for
    /// "leave the game?" and the wrong one here, because the clock is still
    /// running, the board is still the thing being looked at, and a stray click
    /// should not answer for you. Then a note floated into the top corner of
    /// the column, which is comfortable on a Mac and lands on the Resign button
    /// of an iPhone SE — a hundred and fifty points under the board, and a
    /// notice is most of them.
    ///
    /// So it takes the layout's notice slot: the head of the reading column
    /// wherever that column is, in the flow rather than over it. It pushes the
    /// reading down, which costs a scroll, and covers nothing at all — not the
    /// position, not the controls, on any screen the app runs on. The board
    /// underneath stays playable while you decide, because the clock does not
    /// stop for a question and neither should the position.
    @ViewBuilder
    private func drawOffer(_ session: MatchSession) -> some View {
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
            .transition(.opacity.combined(with: .move(edge: .top)))
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
            if isPlaying(session), let reason = unratedReason(session) {
                Text(reason.text).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }

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

    private func holdWhilePlaying(_ session: MatchSession) {
        activity.hold(
            title: L.t("online.leaveTheGame", "Leave the game?"),
            reason: unratedReason(session) == nil
                ? L.t("online.leavingAnOnlineGameLoses", "Leaving an online game loses it and costs you rating.")
                : L.t("online.leavingAFriendlyGame", "Leaving loses the game, but this one is not rated.")
        )
    }

    /// Why the game on the board does not count, if it does not. The match
    /// knows about invitations and rematches; the app remembers whom this
    /// player has had a rated game against today.
    private func unratedReason(_ session: MatchSession) -> UnratedReason? {
        if let call = ratingCall, call.session == ObjectIdentifier(session), call.game == session.gameNumber {
            return call.reason
        }
        if let reason = session.unratedByMatch { return reason }
        if let opponent = session.opponent?.playerID, !app.progress.canRate(against: opponent) {
            return .sameOpponentToday
        }
        return nil
    }

    /// Settled as the game begins and kept until it is scored, so the answer
    /// cannot change halfway — a rated game is itself what makes the next one
    /// against the same opponent unrated.
    private func decideRating(_ session: MatchSession) {
        let game = RatingCall(session: ObjectIdentifier(session), game: session.gameNumber, reason: nil)
        guard ratingCall?.session != game.session || ratingCall?.game != game.game else { return }
        ratingCall = RatingCall(session: game.session, game: game.game, reason: unratedReason(session))
    }

    private func isPlaying(_ session: MatchSession) -> Bool {
        if case .playing = session.phase { return true }
        return false
    }

    /// This side as the opponent should now see it: the rating the game just
    /// played left, for the next one to be scored against.
    private func hello(for session: MatchSession) -> MatchPacket.Hello {
        let rated = RatedPool.online(minutes: session.timeControl.minutes)
        return MatchPacket.Hello(
            playerID: session.me.playerID,
            name: session.me.name,
            rating: app.progress.rating(rated),
            games: app.progress.gamesPlayed(rated)
        )
    }

    /// Apply the rating exactly once, the moment the game ends.
    private func settleIfFinished() {
        guard let session = matchmaker.session, settled == nil,
              case .finished(let finished) = session.phase else { return }
        // The game's own clock, not the lobby's: a game that began from an
        // invitation is on whatever clock the invitation said.
        let control = session.timeControl
        decideRating(session)
        let result: MatchResult
        if unratedReason(session) != nil {
            // A friendly: the result stands, and nobody's rating moves.
            result = finished
        } else {
            guard let rated = session.settle(
                rating: app.progress.rating(.online(minutes: control.minutes)),
                games: app.progress.gamesPlayed(.online(minutes: control.minutes))
            ) else { return }
            result = rated
            app.recordOnline(rated, at: control, against: session.opponent?.playerID)
        }
        settled = result
        activity.release()
        matchmaker.onMatchFinished?(result)
    }

    private func completion(for result: MatchResult, at control: TimeControl, unrated: UnratedReason?) -> CompletionResult {
        let verdict: CompletionResult.Verdict = switch result.outcome {
        case .win: .success
        case .draw: .partial
        case .loss: .failure
        }
        return CompletionResult(
            verdict: verdict,
            title: result.headline,
            detail: result.ratingDelta == 0
                ? unrated?.text
                : L.t("online.ratingChange", "Rating %1$@ → %2$lld",
                      "\(result.ratingDelta > 0 ? "+" : "")\(result.ratingDelta)",
                      app.progress.rating(.online(minutes: control.minutes))),
            line: nil
        )
    }
}

/// Another game, asked for and answered in the result panel itself. The two
/// players are still connected to each other, so there is no invitation to
/// send and nobody to find: one asks, the other says yes, and the board is
/// set up again with the colours swapped.
private struct RematchPanel: View {
    let session: MatchSession
    /// This side as it now stands, rating and all — see `OnlineScreen.hello`.
    let hello: () -> MatchPacket.Hello

    private var name: String { session.opponent?.name ?? L.t("online.opponent", "Opponent") }
    private var nextColour: String { L.color(session.myColor.opponent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if session.opponentLeft {
                Text(L.t("online.opponentLeft", "%@ has left.", name))
                    .appFont(.subheadline)
                    .foregroundStyle(Theatre.ivoryDim)
            } else if session.rematchOffered {
                Text(L.t("online.rematchOffered", "%1$@ wants another game. You would play %2$@.", name, nextColour))
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button {
                        session.respondToRematch(accept: true, as: hello())
                    } label: {
                        Text(L.t("online.accept", "Accept")).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                    Button {
                        session.respondToRematch(accept: false)
                    } label: {
                        Text(L.t("online.decline", "Decline")).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                }
            } else if session.rematchOfferSent {
                HStack(spacing: 9) {
                    BrassActivityIndicator(size: 15)
                    Text(L.t("online.rematchWaiting", "Asking %@ for another game…", name))
                        .appFont(.subheadline)
                        .foregroundStyle(Theatre.ivoryDim)
                }
            } else if session.rematchDeclined {
                Text(L.t("online.rematchDeclined", "%@ does not want another game.", name))
                    .appFont(.subheadline)
                    .foregroundStyle(Theatre.ivoryDim)
            } else {
                Button {
                    session.offerRematch(as: hello())
                } label: {
                    Label {
                        Text(L.t("online.playAgain", "Play again"))
                    } icon: {
                        BrassIcon("arrow.clockwise", size: 17)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                Text(L.t("online.rematchDetail", "The same clock, colours swapped: you would play %@.", nextColour))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
                Text(UnratedReason.rematch.text)
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: session.rematchOffered)
        .animation(.easeOut(duration: 0.2), value: session.rematchOfferSent)
    }
}

/// The rating decided for one game of one match.
private struct RatingCall {
    let session: ObjectIdentifier
    let game: Int
    let reason: UnratedReason?
}

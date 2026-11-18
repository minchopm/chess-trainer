import ChessCore
import ChessTraining
import Combine
import SwiftUI

/// Playing a real person on the clock over the Brass Pawn online service (with
/// Game Center native invitations and App Clip links supported alongside).
struct OnlineScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivityGuard.self) private var activity
    @Environment(Navigator.self) private var navigator
    private var matchmaker: GameCenterMatchmaker { app.matchmaker }

    @State private var timeControl = TimeControl.five
    @State private var settled: MatchResult?
    @State private var ratingCall: RatingCall?
    @State private var scoring: Scoring?
    @State private var invitation: Invitation?
    @State private var inviteCodeInput = ""
    @State private var people: PeopleScreen.Kind?

    #if DEBUG
    @State private var didRunDebugLaunchAction = false
    @State private var autoMoveCursor = 0
    @State private var lastAutoPlayedTurn = ""
    #endif

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Group {
                if let session = matchmaker.session {
                    game(session)
                } else {
                    lobby
                }
            }

            if let code = matchmaker.notice {
                BrassModalBackdrop(onBackdropTap: { matchmaker.notice = nil }) {
                    BrassModalPanel(tint: Theatre.brass) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L.t("online.playOnline", "Play online"))
                                .appFont(.title3, weight: .semibold)
                                .foregroundStyle(Theatre.ivory)
                            Text(noticeMessage(for: code))
                                .appFont(.subheadline)
                                .foregroundStyle(Theatre.ivoryDim)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(L.t("common.ok", "OK")) {
                                matchmaker.notice = nil
                            }
                            .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .zIndex(5)
            }
        }
        .onReceive(ticker) { instant in
            matchmaker.tick(now: instant)
            settleIfFinished()
        }
        .onAppear {
            switch matchmaker.state {
            case .signedOut, .failed:
                matchmaker.authenticate()
            default:
                if !app.service.isSignedIn && !app.service.isConnecting {
                    Task { await app.announceOnline() }
                } else if app.service.isSignedIn {
                    app.service.startEvents()
                }
            }
            if invitation == nil, let waiting = SharedContainer.takeInvitation() {
                invitation = waiting
                timeControl = TimeControl(rawValue: waiting.minutes) ?? .five
            }
            consumePendingInviteCodeIfReady()
            #if DEBUG
            stageDrawOfferForScreenshot()
            stagePlayersForScreenshot()
            runDebugLaunchActionIfReady()
            #endif
        }
        .onChange(of: app.service.isSignedIn) { _, signedIn in
            if signedIn {
                app.service.startEvents()
                consumePendingInviteCodeIfReady()
                #if DEBUG
                runDebugLaunchActionIfReady()
                #endif
            }
        }
        .onChange(of: navigator.pendingInviteCode) { _, _ in
            consumePendingInviteCodeIfReady()
        }
        .task(id: timeControl) {
            await app.boards.refreshLooking(using: app.service)
        }
        .appCover(item: $people) { kind in
            PeopleScreen(kind: kind, clock: timeControl) { player, control in
                invite(player, on: control)
            }
        }
        .onDisappear {
            if people == nil {
                matchmaker.cancelSearch()
            }
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

    private func noticeMessage(for code: String) -> String {
        switch code {
        case "unknown", "no-invite", "invite-unknown":
            L.t("online.codeUnknown", "Nobody is waiting on that code. Ask for a new one.")
        case "own-code":
            L.t("online.ownCode", "That is your own invitation code. Share it with somebody else.")
        case "busy", "in-match":
            L.t("online.busy", "Finish the game under way first.")
        default:
            L.t("online.offline", "The server cannot be reached. Check the connection and try again.")
        }
    }

    private func consumePendingInviteCodeIfReady() {
        if navigator.pendingInviteCode == nil, let stored = SharedContainer.takeInviteCode() {
            navigator.pendingInviteCode = stored
        }
        guard let pending = navigator.pendingInviteCode,
              app.service.isSignedIn,
              matchmaker.session == nil,
              !isSearching
        else { return }
        navigator.pendingInviteCode = nil
        inviteCodeInput = pending
        matchmaker.joinServiceInvite(code: pending)
    }

    // MARK: - Lobby

    private var lobby: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    Text(L.t("online.playOnline", "Play online")).appFont(size: 22, weight: .semibold)
                    Text(L.t("online.intro", "A real opponent, on the clock. No hints, no engine, no take-backs."))
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
                    .disabled(isSearching || matchmaker.activeInviteCode != nil)
                    Text(L.t("online.clockExplanation", "%@ each — %@. You are only paired with players who chose the same clock.", timeControl.label, timeControl.name.lowercased()))
                        .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    LookingNow(count: app.boards.lookingNow[timeControl], control: timeControl)
                }

                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayLocalName).appFont(.subheadline, weight: .semibold)
                            Text(verbatim: "\(displayedRating(for: timeControl))")
                                .appFont(size: 22, weight: .semibold).monospacedDigit()
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L.t("online.record", "Record")).appFont(.caption2).textCase(.uppercase).foregroundStyle(Theatre.ivoryDim)
                            Text(verbatim: "\(app.progress.onlineWins)–\(app.progress.onlineLosses)–\(app.progress.onlineDraws)")
                                .appFont(.subheadline).monospacedDigit().foregroundStyle(Theatre.ivoryDim)
                        }
                    }
                    if app.service.isConnecting {
                        HStack(spacing: 8) {
                            BrassActivityIndicator(size: 14)
                            Text(L.t("online.connecting", "Connecting…"))
                                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                        }
                    } else if let offline = app.service.offlineReason, !app.service.isSignedIn {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.t("online.offline", "The server cannot be reached. Check the connection and try again."))
                                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                            Button(L.t("common.tryAgain", "Try again")) {
                                Task { await app.announceOnline() }
                            }
                            .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                        }
                        .accessibilityIdentifier("offline-\(offline)")
                    } else {
                        Text(matchmaker.status).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                }

                if isSearching {
                    Button(role: .destructive) {
                        matchmaker.cancelSearch()
                    } label: {
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
                    Button { search(timeControl) } label: {
                        Text(matchmaker.isAuthenticated
                             ? L.t("online.findOpponent", "Find opponent")
                             : L.t("online.signIn", "Sign in to Game Center"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .solid))
                    .disabled(matchmaker.activeInviteCode != nil)
                }

                inviteCard
                playersCard

                #if DEBUG
                Button {
                    matchmaker.startLoopbackMatch(
                        timeControl: timeControl,
                        rating: displayedRating(for: timeControl),
                        games: app.progress.gamesPlayed(.online(minutes: timeControl.minutes))
                    )
                } label: {
                    Text(L.t("online.localTestGame", "Local test game"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(emphasis: .quiet, usesBodySize: true))
                #endif
            }
            .padding(12)
        }
    }

    private var displayLocalName: String {
        app.service.alias.isEmpty ? matchmaker.localName : app.service.alias
    }

    private func displayedRating(for control: TimeControl) -> Int {
        if app.service.isSignedIn, let rec = app.service.records[control.minutes] {
            return rec.rating
        }
        return app.progress.rating(.online(minutes: control.minutes))
    }

    // MARK: - Players

    @ViewBuilder
    private var playersCard: some View {
        if matchmaker.canInvite || app.boards.hasLoaded {
            let boards = app.boards
            let online = Array(boards.onlineNow().prefix(3))
            let recent = Array(boards.recent.filter { p in !online.contains { $0.id == p.id } }.prefix(max(0, 3 - online.count)))
            let active = Array(boards.active().filter { p in
                !online.contains { $0.id == p.id } && !recent.contains { $0.id == p.id }
            }.prefix(max(0, 4 - online.count - recent.count)))
            let preview = online + recent + active

            Card {
                Slug(text: L.t("online.players", "Players"))
                if !boards.hasLoaded && boards.isLoading {
                    HStack(spacing: 9) {
                        BrassActivityIndicator(size: 15)
                        Text(L.t("online.loadingLists", "Reading the lists…"))
                            .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                    }
                } else if preview.isEmpty {
                    Text(L.t("online.nobodyYet", "Nobody else has played online yet. Invite somebody with a link from the lobby."))
                        .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                } else {
                    VStack(spacing: 2) {
                        ForEach(preview) { player in
                            PlayerRow(
                                player: player,
                                showsRank: false,
                                invite: isSearching || matchmaker.session != nil || !boards.canInvite(player)
                                    ? nil
                                    : { invite(player, on: timeControl) }
                            )
                        }
                    }
                }
                HStack(spacing: 8) {
                    ForEach([PeopleScreen.Kind.ranks, .players, .friends]) { kind in
                        let waiting = kind == .friends ? boards.incoming.count + app.friendInvites.count : 0
                        Button { people = kind } label: {
                            Text(verbatim: waiting > 0 ? "\(kind.title) · \(waiting)" : kind.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                    }
                }
            }
        }
    }

    private func search(_ control: TimeControl, invitation: Invitation? = nil) {
        let pool = RatedPool.online(minutes: control.minutes)
        matchmaker.findOpponent(
            timeControl: control,
            rating: displayedRating(for: control),
            games: app.progress.gamesPlayed(pool),
            deviation: app.progress.deviation(pool),
            invitation: invitation
        )
    }

    private func invite(_ player: BoardPlayer, on control: TimeControl) {
        timeControl = control
        #if canImport(GameKit)
        matchmaker.invite(player, on: control, from: app.boards)
        #else
        if app.boards.friendState(of: player) == .friend, let key = player.key {
            matchmaker.offerServiceFriend(key: key, alias: player.alias, timeControl: control)
        }
        #endif
    }

    // MARK: - Invitations (Service Codes & App Clip Links)

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
                    search(control, invitation: invitation)
                }
                .buttonStyle(PillButtonStyle(emphasis: .solid))
                .disabled(isSearching || !matchmaker.isAuthenticated)

                Button(L.t("online.decline", "Decline")) { self.invitation = nil }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost))
            }
        }
    }

    @ViewBuilder
    private var inviteCard: some View {
        if matchmaker.isAuthenticated || app.service.isSignedIn {
            Card {
                Slug(text: L.t("online.inviteSomebody", "Invite somebody"))
                Text(L.t(
                    "online.serviceInviteExplanation",
                    "Send the link, or read the code out. Whoever opens it is put straight through to you, on iPhone, iPad, Mac or Android."
                ))
                .appFont(.footnote)
                .foregroundStyle(Theatre.ivoryDim)

                if let active = matchmaker.activeInviteCode {
                    let shareURL = URL(string: active.link) ?? URL(string: "https://brasspawn.com/play?i=\(active.code)")!
                    let clockLabel = (TimeControl(rawValue: active.minutes) ?? timeControl).label
                    Text(verbatim: active.code)
                        .appFont(size: 30, weight: .semibold)
                        .monospacedDigit()
                        .tracking(5)
                        .foregroundStyle(Theatre.brassHot)
                        .padding(.vertical, 4)
                    Text(L.t("online.inviteWaiting", "Code %@ — waiting for them to join. Tap to cancel.", active.code))
                        .appFont(.caption)
                        .foregroundStyle(Theatre.ivoryDim)
                    HStack(spacing: 10) {
                        ShareLink(
                            item: shareURL,
                            subject: Text(verbatim: "Brass Pawn"),
                            message: Text(L.t(
                                "online.inviteMessage",
                                "A game of chess, %@ each: %@",
                                clockLabel,
                                "\(shareURL.absoluteString) (\(active.code))"
                            ))
                        ) {
                            Text(L.t("online.sendTheLink", "Send the link"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))

                        Button(L.t("common.cancel", "Cancel")) {
                            matchmaker.cancelServiceInvite()
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Button {
                        matchmaker.createServiceInvite(timeControl: timeControl)
                    } label: {
                        Text(L.t("online.invite", "Invite"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost))
                    .disabled(isSearching)

                    Divider().overlay(Theatre.ruleSoft).padding(.vertical, 2)

                    Text(L.t("online.joinWithCode", "Have a code?"))
                        .appFont(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(Theatre.ivoryDim)

                    HStack(spacing: 8) {
                        TextField(
                            L.t("online.inviteCode", "Invitation code"),
                            text: Binding(
                                get: { inviteCodeInput },
                                set: { raw in
                                    let filtered = raw.uppercased().unicodeScalars.filter {
                                        ($0.value >= 65 && $0.value <= 90) || ($0.value >= 48 && $0.value <= 57)
                                    }
                                    inviteCodeInput = String(String.UnicodeScalarView(filtered).prefix(6))
                                }
                            )
                        )
                        .appFont(.subheadline, weight: .semibold)
                        .monospacedDigit()
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        #if canImport(UIKit)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .onSubmit {
                            if inviteCodeInput.count == 6 && !isSearching {
                                matchmaker.joinServiceInvite(code: inviteCodeInput)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background { BrassPlateShape(cut: 8).fill(Theatre.ink2) }
                        .overlay { BrassPlateShape(cut: 8).strokeBorder(Theatre.brassDeep.opacity(0.5), lineWidth: 0.7) }

                        Button {
                            matchmaker.joinServiceInvite(code: inviteCodeInput)
                        } label: {
                            Text(L.t("online.join", "Join"))
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                        .disabled(isSearching || inviteCodeInput.count != 6)
                    }
                }
            }
        }
    }

    #if DEBUG
    private func runDebugLaunchActionIfReady() {
        guard !didRunDebugLaunchAction, app.service.isSignedIn else { return }
        let debug = OnlineDebugOptions.current
        if let seekMinutes = debug.autoSeekMinutes {
            didRunDebugLaunchAction = true
            let control = TimeControl(rawValue: seekMinutes) ?? .five
            timeControl = control
            search(control)
        } else if let joinCode = debug.autoJoinCode {
            didRunDebugLaunchAction = true
            inviteCodeInput = joinCode
            matchmaker.joinServiceInvite(code: joinCode)
        } else if let inviteMinutes = debug.autoCreateInviteMinutes {
            didRunDebugLaunchAction = true
            let control = TimeControl(rawValue: inviteMinutes) ?? .five
            timeControl = control
            matchmaker.createServiceInvite(timeControl: control)
        } else if let rankMinutes = debug.autoShowRanksMinutes {
            didRunDebugLaunchAction = true
            let control = TimeControl(rawValue: rankMinutes) ?? .five
            timeControl = control
            Task { @MainActor in
                await app.boards.refresh(using: app.service)
                people = .ranks
            }
        }
    }

    private func stagePlayersForScreenshot() {
        switch ScreenshotScene.requested {
        case .onlineLobby:
            app.boards.fillWithSamples()
        case .players:
            app.boards.fillWithSamples()
            people = .ranks
        case .playersAll:
            app.boards.fillWithSamples()
            people = .players
        case .friends:
            app.boards.fillWithSamples()
            people = .friends
        case .friendOffer:
            app.boards.fillWithSamples()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                app.heard([FriendInvite(id: String(repeating: "c", count: 32), alias: "Ana P.", minutes: 10)])
            }
        case .onlineRematch:
            guard matchmaker.session == nil else { return }
            matchmaker.startLoopbackMatch(timeControl: timeControl,
                                          rating: app.progress.rating(.online(minutes: timeControl.minutes)),
                                          games: 3)
            Task { @MainActor in
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

    private func performAutoMoveIfNeeded(_ session: MatchSession) async {
        let debug = OnlineDebugOptions.current
        guard !debug.autoMoves.isEmpty || debug.autoPlayAny else { return }
        guard case .playing = session.phase, session.isMyTurn else { return }
        let turnKey = "\(ObjectIdentifier(session))-\(session.gameNumber)-\(session.uciMoves.count)"
        guard lastAutoPlayedTurn != turnKey else { return }

        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled, case .playing = session.phase, session.isMyTurn else { return }
        guard lastAutoPlayedTurn != turnKey else { return }

        let legalMoves = session.position.legalMoves()
        guard !legalMoves.isEmpty else { return }

        if autoMoveCursor < debug.autoMoves.count {
            let candidateUCI = debug.autoMoves[autoMoveCursor]
            autoMoveCursor += 1
            if let parsed = Move(uci: candidateUCI),
               let legal = legalMoves.first(where: { $0.matchesNotation(of: parsed) }) {
                lastAutoPlayedTurn = turnKey
                session.play(from: legal.from, to: legal.to, promotion: legal.promotion)
                return
            }
        }

        // Also check if any remaining scripted move is immediately legal before falling back.
        while autoMoveCursor < debug.autoMoves.count {
            let candidateUCI = debug.autoMoves[autoMoveCursor]
            if let parsed = Move(uci: candidateUCI),
               let legal = legalMoves.first(where: { $0.matchesNotation(of: parsed) }) {
                autoMoveCursor += 1
                lastAutoPlayedTurn = turnKey
                session.play(from: legal.from, to: legal.to, promotion: legal.promotion)
                return
            }
            if !debug.autoPlayAny {
                autoMoveCursor += 1
            } else {
                break
            }
        }

        guard debug.autoPlayAny else { return }
        // Prefer an immediate checkmate, then a capture, then the first legal move.
        let chosen = legalMoves.first { move in
            var next = session.position
            next.make(move)
            return next.isCheckmate
        } ?? legalMoves.first { move in
            session.position[move.to] != nil
        } ?? legalMoves[0]

        lastAutoPlayedTurn = turnKey
        session.play(from: chosen.from, to: chosen.to, promotion: chosen.promotion)
    }
    #endif

    private var isSearching: Bool {
        if case .searching = matchmaker.state { return true }
        return false
    }

    // MARK: - The Game

    private func game(_ session: MatchSession) -> some View {
        let opponentName = session.opponent?.name
            ?? matchmaker.serviceMatch?.info.opponent.alias
            ?? L.t("online.opponent", "Opponent")
        let opponentRating = session.opponent?.rating
            ?? matchmaker.serviceMatch?.info.opponent.record.rating

        return TrainingLayout { width in
            BoardStage(
                width: width,
                top: PlayerBar(
                    name: opponentName,
                    rating: opponentRating,
                    color: session.myColor.opponent,
                    material: MaterialBalance(session.position)
                ),
                bottom: PlayerBar(
                    name: displayLocalName,
                    rating: displayedRating(for: session.timeControl),
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
            statusCard(session, opponentName: opponentName)
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
                    result: completion(for: settled ?? result, session: session),
                    primaryTitle: L.t("online.backToTheLobby", "Back to the lobby"),
                    onPrimary: {
                        matchmaker.leaveMatch()
                        settled = nil
                        ratingCall = nil
                        scoring = nil
                    },
                    onRetry: nil,
                    accessory: AnyView(RematchPanel(
                        session: session,
                        isClosed: matchmaker.isMatchClosed,
                        hello: { hello(for: session) }
                    )),
                    primaryEmphasis: session.opponentLeft || matchmaker.isMatchClosed || session.rematchDeclined ? .solid : .ghost
                )
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
            }
        }
        .animation(.easeOut(duration: 0.2), value: session.drawOffered)
        .onChange(of: session.gameNumber) { _, _ in
            settled = nil
            scoring = nil
            #if DEBUG
            autoMoveCursor = 0
            lastAutoPlayedTurn = ""
            #endif
        }
        .onChange(of: session.moves.count) { _, _ in
            SoundBoard.shared.play(.move)
        }
        .onAppear {
            #if DEBUG
            autoMoveCursor = 0
            lastAutoPlayedTurn = ""
            #endif
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
        #if DEBUG
        .task(id: "\(ObjectIdentifier(session))-\(session.gameNumber)-\(isPlaying(session))-\(session.isMyTurn)-\(session.uciMoves.count)") {
            await performAutoMoveIfNeeded(session)
        }
        #endif
        .animation(.spring(duration: 0.35), value: settled)
    }

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

    private func statusCard(_ session: MatchSession, opponentName: String) -> some View {
        Card {
            Text(statusText(session)).appFont(size: 22, weight: .semibold)
            Text(L.t("online.gameSummary", "%@ · %@ · you are %@", session.timeControl.label, session.timeControl.name, L.color(session.myColor)))
                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            if isPlaying(session), let reason = unratedReason(session) {
                Text(reason.text).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }
            if isPlaying(session), !matchmaker.isOpponentConnected {
                Text(L.t("online.opponentAway", "%@ has lost the connection — waiting for them to come back.", opponentName))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.warn)
            }
            if session.drawOfferSent {
                Text(L.t("online.drawOfferedWaitingForAn", "Draw offered — waiting for an answer."))
                    .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }
        }
    }

    private func statusText(_ session: MatchSession) -> String {
        switch session.phase {
        case .waiting:
            L.t("online.connecting", "Connecting…")
        case .playing:
            session.isMyTurn
                ? L.t("play.yourMove", "Your move.")
                : L.t("board.toMove", "%@ to move.", L.color(session.position.sideToMove))
        case .finished(let result):
            result.headline
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

    private func unratedReason(_ session: MatchSession) -> UnratedReason? {
        if let call = ratingCall, call.session == ObjectIdentifier(session), call.game == session.gameNumber {
            return call.reason
        }
        if let reason = session.unratedByMatch { return reason }
        let opponentID = matchmaker.serviceMatch?.info.opponent.id ?? session.opponent?.playerID
        if let opponentID, !app.progress.canRate(against: opponentID) {
            return .sameOpponentToday
        }
        return nil
    }

    private func decideRating(_ session: MatchSession) {
        let game = RatingCall(session: ObjectIdentifier(session), game: session.gameNumber, reason: nil)
        guard ratingCall?.session != game.session || ratingCall?.game != game.game else { return }
        ratingCall = RatingCall(session: game.session, game: game.game, reason: unratedReason(session))
    }

    private func isPlaying(_ session: MatchSession) -> Bool {
        if case .playing = session.phase { return true }
        return false
    }

    private func hello(for session: MatchSession) -> MatchPacket.Hello {
        let rated = RatedPool.online(minutes: session.timeControl.minutes)
        let rec = app.service.records[session.timeControl.minutes]
        return MatchPacket.Hello(
            playerID: session.me.playerID,
            name: displayLocalName,
            rating: rec?.rating ?? app.progress.rating(rated),
            games: rec?.games ?? app.progress.gamesPlayed(rated),
            deviation: rec?.deviation ?? app.progress.deviation(rated)
        )
    }

    private func settleIfFinished() {
        guard let session = matchmaker.session, settled == nil,
              case .finished(let finished) = session.phase else { return }
        let control = session.timeControl
        decideRating(session)
        settled = finished
        activity.release()
        matchmaker.onMatchFinished?(finished)

        // Service matches are scored authoritatively by the server (`OnlineGameResult`).
        guard !matchmaker.isServiceMatch else { return }

        var reason = unratedReason(session)
        #if DEBUG
        let loopback = matchmaker.isLoopback
        #else
        let loopback = false
        #endif
        if reason == nil, session.uciMoves.count < 2, !loopback { reason = .aborted }
        if let reason {
            scoring = .unrated(reason)
            return
        }
        let mine = app.progress.onlineRecord(control)
        let theirs = session.opponentAsTheySaid
        guard let (rated, record) = session.settle(mine, against: theirs) else { return }
        settled = rated
        let theirsAfter = theirs.after(1 - rated.score, against: mine)
        app.recordOnline(record, result: rated, at: control, against: session.opponent?.playerID,
                         opponentAfter: theirsAfter)
        scoring = .rated(before: mine.rating, after: record.rating, delta: rated.ratingDelta)
    }

    private func effectiveScoring(for session: MatchSession) -> Scoring? {
        if matchmaker.isServiceMatch {
            if let serverResult = matchmaker.serviceResult, serverResult.game == session.gameNumber {
                if serverResult.rated {
                    let after = serverResult.record.rating
                    let before = after - serverResult.delta
                    return .rated(before: before, after: after, delta: serverResult.delta)
                }
                return .unrated(serverResult.unratedReason)
            }
            if let reason = session.unratedByMatch {
                return .unrated(reason)
            }
            return nil
        }
        return scoring
    }

    private func completion(for result: MatchResult, session: MatchSession) -> CompletionResult {
        let verdict: CompletionResult.Verdict = switch result.outcome {
        case .win: .success
        case .draw: .partial
        case .loss: .failure
        }
        let activeScoring = effectiveScoring(for: session)
        return CompletionResult(
            verdict: verdict,
            title: result.headline,
            detail: activeScoring.map { item in
                switch item {
                case .rated(let before, let after, let delta):
                    let sign = delta >= 0 ? "+" : "−"
                    return L.t("online.ratingChange", "Rating %1$@ → %2$lld", "\(before)", after)
                        + "  (\(sign)\(abs(delta)))"
                case .unrated(let reason):
                    return reason.text
                }
            },
            line: nil
        )
    }
}

private struct RematchPanel: View {
    let session: MatchSession
    let isClosed: Bool
    let hello: () -> MatchPacket.Hello

    private var name: String { session.opponent?.name ?? L.t("online.opponent", "Opponent") }
    private var nextColour: String { L.color(session.myColor.opponent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if session.opponentLeft || isClosed {
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
                    .fixedSize(horizontal: false, vertical: true)
                Text(UnratedReason.rematch.text)
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: session.rematchOffered)
        .animation(.easeOut(duration: 0.2), value: session.rematchOfferSent)
    }
}

private struct RatingCall {
    let session: ObjectIdentifier
    let game: Int
    let reason: UnratedReason?
}

private enum Scoring: Equatable {
    case rated(before: Int, after: Int, delta: Int)
    case unrated(UnratedReason)
}

import ChessTraining
import SwiftUI

/// Rank list, online players, and friends backed by the Brass Pawn online service.
struct PeopleScreen: View {
    enum Kind: String, CaseIterable, Identifiable {
        case ranks, players, friends
        var id: String { rawValue }

        var title: String {
            switch self {
            case .ranks: L.t("online.rankList", "Rank list")
            case .players: L.t("online.players", "Players")
            case .friends: L.t("online.friends", "Friends")
            }
        }
    }

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State var kind: Kind
    @State var clock: TimeControl
    @State private var rankScope: OnlineBoards.Scope = .top
    @State private var query = ""
    @State private var searchResults: [BoardPlayer]?
    @State private var busy: Set<String> = []
    let onInvite: (BoardPlayer, TimeControl) -> Void

    init(kind: Kind, clock: TimeControl, onInvite: @escaping (BoardPlayer, TimeControl) -> Void) {
        _kind = State(initialValue: kind)
        _clock = State(initialValue: clock)
        self.onInvite = onInvite
    }

    private var boards: OnlineBoards { app.boards }

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: kind.title) { dismiss() }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    BrassSegmentedPicker(
                        L.t("common.mode", "Mode"),
                        selection: $kind,
                        options: Array(Kind.allCases)
                    ) { tab in
                        Text(tab.title)
                    }

                    Card {
                        Text(L.t("online.clock", "Clock")).appFont(.caption).textCase(.uppercase)
                            .foregroundStyle(Theatre.ivoryDim)
                        BrassSegmentedPicker(L.t("online.clock", "Clock"), selection: $clock,
                                             options: Array(TimeControl.allCases)) { control in
                            Text(verbatim: "\(control.minutes)")
                        }
                        LookingNow(count: boards.lookingNow[clock], control: clock)
                    }

                    BrassSearchField(placeholder: L.t("online.searchPlayers", "Search by nickname"), text: $query)

                    if !boards.hasLoaded && boards.isLoading {
                        HStack(spacing: 9) {
                            BrassActivityIndicator(size: 15)
                            Text(L.t("online.loadingLists", "Reading the lists…"))
                                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        switch kind {
                        case .ranks: ranks
                        case .players: players
                        case .friends: friends
                        }
                    }

                    Text(kind == .friends
                         ? L.t("online.friendsHow", "Anybody on the rank list or among the players can be asked to be friends with the button on their row. Once they say yes, they are here, and a game with them is a tap away. Games with friends are friendly games.")
                         : L.t("online.friendlyNote", "Invitations and rematches are friendly games, and only one game a day against the same opponent is rated: a place on the list is won against whoever the search finds."))
                        .appFont(.caption2)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)

                    Text(L.t("online.servicePlayersNote", "Nicknames and ratings are kept by Brass Pawn's own game service, the same for iPhone, iPad, Mac and Android. Online now means the app is on their screen."))
                        .appFont(.caption2)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
                .padding(12)
                .padding(.bottom, 30)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await boards.refresh(using: app.service)
                await boards.loadScope(rankScope, on: clock, using: app.service)
                app.heard(await boards.refreshFriends(using: app.service))
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .task {
            if !boards.hasLoaded {
                await boards.refresh(using: app.service)
            }
        }
        .task(id: "\(clock.minutes)-\(rankScope.rawValue)") {
            await boards.loadScope(rankScope, on: clock, using: app.service)
            await boards.refreshLooking(using: app.service)
        }
        .task(id: kind == .friends) {
            app.heard(await boards.refreshFriends(using: app.service, askingGameCenter: kind == .friends))
        }
        .task(id: "\(query)-\(clock.minutes)") {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                searchResults = nil
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            searchResults = await boards.search(query: trimmed, on: clock, using: app.service)
        }
        .task {
            while !Task.isCancelled {
                await boards.refreshPresence(using: app.service)
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    // MARK: - Searching

    private var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func matches(_ player: BoardPlayer) -> Bool {
        let wanted = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return wanted.isEmpty || player.alias.localizedStandardContains(wanted)
    }

    private func mergedSearch(with local: [BoardPlayer]) -> [BoardPlayer] {
        var seen = Set<String>()
        var combined: [BoardPlayer] = []
        for p in local where seen.insert(p.key ?? p.id).inserted {
            combined.append(p)
        }
        for p in (searchResults ?? []) where seen.insert(p.key ?? p.id).inserted {
            combined.append(p)
        }
        return combined
    }

    // MARK: - Rank List

    @ViewBuilder
    private var ranks: some View {
        BrassSegmentedPicker(
            L.t("online.rankList", "Rank list"),
            selection: $rankScope,
            options: Array(OnlineBoards.Scope.allCases)
        ) { scope in
            Text(scope.title)
        }

        let baseEntries = boards.entries(for: clock, scope: rankScope).filter(matches)
        let entries = hasQuery ? mergedSearch(with: baseEntries) : baseEntries

        if !hasQuery {
            Card {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L.t("online.yourPlace", "Your place")).appFont(.caption).textCase(.uppercase)
                            .foregroundStyle(Theatre.ivoryDim)
                        if let me = boards.myEntry(for: clock, scope: rankScope), let rank = me.rank {
                            Text(L.t("online.placeOf", "%1$lld of %2$lld", rank, max(rank, boards.total(for: clock, scope: rankScope))))
                                .appFont(size: 22, weight: .semibold).monospacedDigit()
                        } else {
                            Text(L.t("online.rankEmptyMe", "Play a rated game on this clock to get a place."))
                                .appFont(.footnote)
                                .foregroundStyle(Theatre.ivoryDim)
                        }
                    }
                    Spacer()
                    if let me = boards.myEntry(for: clock, scope: rankScope), let rating = me.rating {
                        Text(verbatim: "\(rating)")
                            .appFont(size: 22, weight: .semibold).monospacedDigit()
                            .foregroundStyle(Theatre.brassHot)
                    }
                }
            }
        }

        if entries.isEmpty {
            empty(hasQuery
                  ? L.t("online.noMatch", "Nobody by that nickname among the players read so far.")
                  : L.t("online.nobodyRanked", "Nobody has a rating on this clock yet. The first game played on it starts the list."))
        } else {
            rows(entries, showsRank: !hasQuery)
        }
    }

    // MARK: - Players & Friends

    @ViewBuilder
    private var players: some View {
        if hasQuery {
            let localMatches = (boards.onlineNow() + boards.active() + boards.inactive()).filter(matches)
            let found = mergedSearch(with: localMatches)
            if found.isEmpty {
                empty(L.t("online.noMatch", "Nobody by that nickname among the players read so far."))
            } else {
                rows(found, showsRank: false)
            }
        } else {
            let online = boards.onlineNow()
            let active = boards.active()
            let inactive = boards.inactive()
            if online.isEmpty && active.isEmpty && inactive.isEmpty {
                empty(L.t("online.nobodyYet", "Nobody else has played online yet. Invite somebody with a link from the lobby."))
            }
            section(L.t("online.presence.online", "Online now"), online)
            section(L.t("online.activeThisWeek", "Active this week"), active)
            section(L.t("online.notSeenThisWeek", "Not seen this week"), inactive)
        }
    }

    @ViewBuilder
    private var friends: some View {
        let all = boards.friends.filter(matches)
        let online = all.filter { boards.status(of: $0) != nil }
        let rest = all.filter { boards.status(of: $0) == nil }
        let incoming = boards.incoming.filter(matches)
        let outgoing = boards.outgoing.filter(matches)
        let gameCenter = boards.gameCenterFriends.filter(matches)
        if all.isEmpty && incoming.isEmpty && outgoing.isEmpty && gameCenter.isEmpty {
            empty(!hasQuery
                  ? L.t("online.noFriendsYet", "No friends yet.")
                  : L.t("online.noMatch", "Nobody by that nickname among the players read so far."))
        }
        section(L.t("online.friendRequests", "Requests"), incoming)
        section(L.t("online.presence.online", "Online now"), online)
        section(L.t("online.friends", "Friends"), rest)
        section(L.t("online.friendsSent", "Sent"), outgoing)
        section(L.t("online.fromGameCenter", "From Game Center"), gameCenter)
    }

    @ViewBuilder
    private func section(_ title: String, _ list: [BoardPlayer]) -> some View {
        if !list.isEmpty {
            Slug(text: title + " · \(list.count)")
                .padding(.horizontal, 4)
                .padding(.top, 6)
            rows(list, showsRank: false)
        }
    }

    private func rows(_ list: [BoardPlayer], showsRank: Bool) -> some View {
        Panel(padding: 6) {
            LazyVStack(spacing: 0) {
                ForEach(list) { player in
                    PlayerRow(player: player, showsRank: showsRank, invite: invite(player),
                              friendship: friendship(player), busy: busy.contains(player.id))
                        .contextMenu {
                            if boards.friendState(of: player) == .friend {
                                Button(role: .destructive) {
                                    change(player) { await boards.unfriend(player, using: app.service) }
                                } label: {
                                    Label(L.t("online.removeFriend", "Remove friend"), systemImage: "person.badge.minus")
                                }
                            }
                        }
                    if player.id != list.last?.id { Rule() }
                }
            }
        }
    }

    private func invite(_ player: BoardPlayer) -> (() -> Void)? {
        if case .playing = boards.status(of: player) { return nil }
        guard !player.isLocal, app.matchmaker.session == nil, boards.canInvite(player),
              boards.friendState(of: player) != .askedBy else { return nil }
        return {
            onInvite(player, clock)
            dismiss()
        }
    }

    private func friendship(_ player: BoardPlayer) -> PlayerRow.Friendship? {
        guard !player.isLocal, player.key != nil else { return nil }
        let befriend = { change(player) { await boards.befriend(player, using: app.service) } }
        let unfriend = { change(player) { await boards.unfriend(player, using: app.service) } }
        switch boards.friendState(of: player) {
        case .none: return .ask(befriend)
        case .asked: return .sent(takeBack: unfriend)
        case .askedBy: return .answer(accept: befriend, decline: unfriend)
        case .friend: return nil
        }
    }

    private func change(_ player: BoardPlayer, _ work: @escaping () async -> Void) {
        guard !busy.contains(player.id) else { return }
        busy.insert(player.id)
        Task {
            await work()
            busy.remove(player.id)
        }
    }

    private func empty(_ text: String) -> some View {
        Text(text)
            .appFont(.footnote)
            .foregroundStyle(Theatre.ivoryDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
    }
}

/// One player row: avatar, nickname, status/last-seen, rating, friend actions, and invite button.
struct PlayerRow: View {
    enum Friendship {
        case ask(() -> Void)
        case sent(takeBack: () -> Void)
        case answer(accept: () -> Void, decline: () -> Void)
    }

    @Environment(AppModel.self) private var app
    let player: BoardPlayer
    let showsRank: Bool
    let invite: (() -> Void)?
    var friendship: Friendship? = nil
    var busy = false

    var body: some View {
        HStack(spacing: 11) {
            if showsRank {
                Text(verbatim: player.rank.map { "\($0)" } ?? "–")
                    .appFont(size: 13, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle((player.rank ?? 99) <= 3 ? Theatre.brassHot : Theatre.ivoryFaint)
                    .frame(width: 28, alignment: .trailing)
            }
            avatar
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(verbatim: player.alias)
                        .appFont(.subheadline, weight: .semibold)
                        .foregroundStyle(player.isLocal ? Theatre.brassHot : Theatre.ivory)
                        .lineLimit(1)
                    if app.boards.friendState(of: player) == .friend {
                        BrassIcon("person.2.fill", size: 11)
                            .foregroundStyle(Theatre.brassHot.opacity(0.8))
                            .accessibilityLabel(L.t("online.friend", "Friend"))
                    }
                }
                if let line = app.boards.status(of: player)?.label ?? seen {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(dot)
                            .frame(width: 6, height: 6)
                        Text(line)
                            .appFont(.caption2)
                            .foregroundStyle(Theatre.ivoryDim)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 6)
            if let rating = player.rating {
                Text(verbatim: "\(rating)")
                    .appFont(size: 16, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(player.isLocal ? Theatre.brassHot : Theatre.ivory)
            }
            if busy {
                BrassActivityIndicator(size: 15)
                    .frame(width: 34, height: 34)
            } else if let friendship {
                friendButtons(friendship)
            }
            if let invite {
                Button(action: invite) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theatre.brassHot)
                        .frame(width: 40, height: 34)
                        .background { BrassPlateShape(cut: 7).fill(Theatre.ink3) }
                        .overlay { BrassPlateShape(cut: 7).strokeBorder(Theatre.brassDeep.opacity(0.7), lineWidth: 0.8) }
                }
                .buttonStyle(BrassPressStyle())
                .accessibilityLabel(L.t("online.invite", "Invite") + " " + player.alias)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background {
            if player.isLocal {
                BrassPlateShape(cut: 7).fill(Theatre.ink4.opacity(0.9))
            }
        }
        .task { await app.boards.loadPhoto(for: player.id) }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func friendButtons(_ friendship: Friendship) -> some View {
        switch friendship {
        case .ask(let ask):
            SquareButton(symbol: "person.badge.plus", label: L.t("online.addAsFriend", "Add as friend") + " " + player.alias,
                         action: ask)
        case .sent(let takeBack):
            SquareButton(symbol: "clock", label: L.t("online.cancelRequest", "Take the request back") + " " + player.alias,
                         dim: true, action: takeBack)
                .help(L.t("online.requestSent", "Request sent"))
        case .answer(let accept, let decline):
            SquareButton(symbol: "xmark", label: L.t("online.decline", "Decline") + " " + player.alias,
                         dim: true, action: decline)
            SquareButton(symbol: "checkmark", label: L.t("online.accept", "Accept") + " " + player.alias,
                         action: accept)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let photo = app.boards.photos[player.id] {
            photo.resizable().scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(Theatre.brassDeep.opacity(0.6), lineWidth: 0.7) }
        } else {
            Text(verbatim: String(player.alias.prefix(1)).uppercased())
                .appFont(size: 15, weight: .semibold)
                .foregroundStyle(Theatre.brassHot)
                .frame(width: 34, height: 34)
                .background { Circle().fill(Theatre.ink4) }
                .overlay { Circle().strokeBorder(Theatre.brassDeep.opacity(0.6), lineWidth: 0.7) }
        }
    }

    private var dot: Color {
        switch app.boards.status(of: player) {
        case .looking, .online: Theatre.good
        case .playing: Theatre.brassHot
        case nil: Theatre.ivoryFaint.opacity(0.45)
        }
    }

    private var seen: String? {
        guard player.lastSeen > .distantPast else {
            return app.boards.recent.contains { $0.id == player.id } ? L.t("online.playedRecently", "Played recently") : nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter.localizedString(for: min(player.lastSeen, Date()), relativeTo: Date())
    }
}

struct LookingNow: View {
    let count: Int?
    let control: TimeControl

    var body: some View {
        if let count, count > 0 {
            HStack(spacing: 6) {
                Circle().fill(Theatre.good).frame(width: 6, height: 6)
                Text(L.t("online.lookingNow", "Looking for a %1$@ game right now: %2$lld", control.label, count))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)
            }
        }
    }
}

private struct SquareButton: View {
    let symbol: String
    let label: String
    var dim = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(dim ? Theatre.ivoryDim : Theatre.brassHot)
                .frame(width: 34, height: 34)
                .background { BrassPlateShape(cut: 7).fill(Theatre.ink3) }
                .overlay { BrassPlateShape(cut: 7).strokeBorder(Theatre.brassDeep.opacity(dim ? 0.4 : 0.7), lineWidth: 0.8) }
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(label)
    }
}

private struct Rule: View {
    var body: some View {
        Rectangle().fill(Theatre.ruleSoft).frame(height: 1).padding(.horizontal, 8)
    }
}

import ChessTraining
import SwiftUI

/// The people to play online, three ways, each a screen of its own from the
/// lobby: the rank list for a clock, everybody who plays, and this player's
/// Game Center friends — a friend is a player too, and is in both. Each list
/// is read a page at a time as it is scrolled, drawn only as far as it is on
/// screen, and searched by nickname; each row has an invitation a tap away.
struct PeopleScreen: View {
    enum Kind: String, Identifiable {
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
    let kind: Kind
    @State var clock: TimeControl
    @State private var query = ""
    /// Invite a player to a game on a clock. The screen goes, and the lobby
    /// shows the invitation going out.
    let onInvite: (BoardPlayer, TimeControl) -> Void

    private var boards: OnlineBoards { app.boards }

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: kind.title, subtitle: L.t("online.gameCenter", "Game Center")) { dismiss() }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Card {
                        Text(L.t("online.clock", "Clock")).appFont(.caption).textCase(.uppercase)
                            .foregroundStyle(Theatre.ivoryDim)
                        BrassSegmentedPicker(L.t("online.clock", "Clock"), selection: $clock,
                                             options: Array(TimeControl.allCases)) { control in
                            Text(verbatim: "\(control.minutes)")
                        }
                        LookingNow(count: boards.lookingNow[clock], control: clock)
                    }

                    if kind == .friends {
                        Button { boards.askForAFriend() } label: {
                            Label {
                                Text(L.t("online.addFriend", "Add a friend"))
                            } icon: {
                                BrassIcon("person.badge.plus", size: 17)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                    }

                    BrassSearchField(placeholder: L.t("online.searchPlayers", "Search by nickname"), text: $query)

                    if !boards.hasLoaded && boards.isLoading {
                        HStack(spacing: 9) {
                            BrassActivityIndicator(size: 15)
                            Text(L.t("online.loadingPlayers", "Reading the lists from Game Center…"))
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
                         ? L.t("online.friendsNote", "Friend requests go through Game Center: it writes a message for you to send, and once it is accepted the two of you are friends here too.")
                         : L.t("online.friendlyNote", "Invitations and rematches are friendly games, and only one game a day against the same opponent is rated: a place on the list is won against whoever the search finds."))
                        .appFont(.caption2)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)

                    Text(L.t("online.playersNote4", "Nicknames and ratings are Game Center's, as each player lets them be shown. Online now means the app is on their screen this minute, for those who show it; active means seen in the last seven days."))
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
            .refreshable { await boards.refresh() }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .task { if !boards.hasLoaded { await boards.refresh() } }
        .task { if kind == .friends { await boards.refreshFriends(asking: true) } }
        // Who is on screen now: asked on arrival and every minute after,
        // for as long as this is open.
        .task {
            while !Task.isCancelled {
                await boards.refreshPresence(using: app.presence)
                try? await Task.sleep(for: .seconds(60))
            }
        }
        .task(id: clock) { await boards.refreshLooking() }
    }

    // MARK: - Searching

    private func matches(_ player: BoardPlayer) -> Bool {
        let wanted = query.trimmingCharacters(in: .whitespaces)
        return wanted.isEmpty || player.alias.localizedStandardContains(wanted)
    }

    /// Game Center cannot look a nickname up, so a search reads the lists:
    /// what has been read is searched as it is typed, and this reads the rest.
    @ViewBuilder
    private func searchFurther(_ clocks: [TimeControl]) -> some View {
        let unread = clocks.map { (boards.totals[$0] ?? 0) - (boards.ranks[$0]?.count ?? 0) }.reduce(0, +)
        if !query.isEmpty, clocks.contains(where: { boards.hasMore(on: $0) }) {
            Button {
                Task { for control in clocks { await boards.loadEverything(on: control) } }
            } label: {
                Text(L.t("online.searchAll", "Search %lld more players", unread))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
        }
    }

    // MARK: - The rank list

    @ViewBuilder
    private var ranks: some View {
        let entries = (boards.ranks[clock] ?? []).filter(matches)
        if query.isEmpty, let me = boards.mine[clock], let rank = me.rank {
            Card {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L.t("online.yourPlace", "Your place")).appFont(.caption).textCase(.uppercase)
                            .foregroundStyle(Theatre.ivoryDim)
                        Text(L.t("online.placeOf", "%1$lld of %2$lld", rank, boards.totals[clock] ?? entries.count))
                            .appFont(size: 22, weight: .semibold).monospacedDigit()
                    }
                    Spacer()
                    if let rating = me.rating {
                        Text(verbatim: "\(rating)")
                            .appFont(size: 22, weight: .semibold).monospacedDigit()
                            .foregroundStyle(Theatre.brassHot)
                    }
                }
            }
        }
        if entries.isEmpty {
            empty(query.isEmpty
                  ? L.t("online.nobodyRanked", "Nobody has a rating on this clock yet. The first game played on it starts the list.")
                  : L.t("online.noMatch", "Nobody by that nickname among the players read so far."))
        } else {
            rows(entries, showsRank: true) {
                if query.isEmpty { Task { await boards.loadMore(on: clock) } }
            }
        }
        searchFurther([clock])
    }

    // MARK: - Everybody, and the friends

    @ViewBuilder
    private var players: some View {
        let online = boards.onlineNow().filter(matches)
        let active = boards.active().filter(matches)
        let inactive = boards.inactive().filter(matches)
        if online.isEmpty && active.isEmpty && inactive.isEmpty {
            empty(query.isEmpty
                  ? L.t("online.nobodyYet", "Nobody else has played online yet. Invite somebody with a link from the lobby.")
                  : L.t("online.noMatch", "Nobody by that nickname among the players read so far."))
        }
        section(L.t("online.presence.online", "Online now"), online)
        section(L.t("online.activeThisWeek", "Active this week"), active)
        section(L.t("online.notSeenThisWeek", "Not seen this week"), inactive) {
            // The end of everybody read so far: read the next page of every clock.
            if query.isEmpty {
                Task { for control in TimeControl.allCases { await boards.loadMore(on: control) } }
            }
        }
        searchFurther(Array(TimeControl.allCases))
    }

    @ViewBuilder
    private var friends: some View {
        if boards.friendsAccess == .denied {
            empty(L.t("online.friendsDenied", "Brass Pawn may not see your Game Center friends. Settings → Game Center → Friends lets it."))
        } else {
            let all = boards.friends.filter(matches)
            let online = all.filter { boards.presence[$0.id] != nil }
            let rest = all.filter { boards.presence[$0.id] == nil }
            if all.isEmpty {
                empty(query.isEmpty
                      ? L.t("online.friendsEmpty", "No Game Center friends play Brass Pawn yet.")
                      : L.t("online.noMatch", "Nobody by that nickname among the players read so far."))
            }
            section(L.t("online.presence.online", "Online now"), online)
            section(L.t("online.friends", "Friends"), rest)
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ list: [BoardPlayer], atEnd: (() -> Void)? = nil) -> some View {
        if !list.isEmpty {
            Slug(text: title + " · \(list.count)")
                .padding(.horizontal, 4)
                .padding(.top, 6)
            rows(list, showsRank: false, atEnd: atEnd)
        }
    }

    /// The rows, drawn only as they come on screen; the last one's arrival is
    /// the moment to read the next page.
    private func rows(_ list: [BoardPlayer], showsRank: Bool, atEnd: (() -> Void)? = nil) -> some View {
        Panel(padding: 6) {
            LazyVStack(spacing: 0) {
                ForEach(list) { player in
                    PlayerRow(player: player, showsRank: showsRank, invite: invite(player))
                        .onAppear { if player.id == list.last?.id { atEnd?() } }
                    if player.id != list.last?.id { Rule() }
                }
            }
        }
    }

    private func invite(_ player: BoardPlayer) -> (() -> Void)? {
        // Nobody in the middle of a game is asked to leave it.
        if case .playing = boards.presence[player.id] { return nil }
        guard !player.isLocal, app.matchmaker.session == nil else { return nil }
        return {
            onInvite(player, clock)
            dismiss()
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

/// One player: their picture or initial, nickname, when they were last seen,
/// their rating, and the invitation.
struct PlayerRow: View {
    @Environment(AppModel.self) private var app
    let player: BoardPlayer
    let showsRank: Bool
    let invite: (() -> Void)?

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
                        .foregroundStyle(Theatre.ivory)
                        .lineLimit(1)
                    if app.boards.isFriend(player.id) {
                        BrassIcon("person.2.fill", size: 11)
                            .foregroundStyle(Theatre.brassHot.opacity(0.8))
                            .accessibilityLabel(L.t("online.friend", "Friend"))
                    }
                }
                HStack(spacing: 5) {
                    Circle()
                        .fill(dot)
                        .frame(width: 6, height: 6)
                    Text(app.boards.presence[player.id]?.label ?? seen)
                        .appFont(.caption2)
                        .foregroundStyle(Theatre.ivoryDim)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            if let rating = player.rating {
                Text(verbatim: "\(rating)")
                    .appFont(size: 16, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(player.isLocal ? Theatre.brassHot : Theatre.ivory)
            }
            if let invite {
                // A paper plane rather than the word: "Invite" in capitals is
                // twice as wide in German or Russian, and the row is a phone's
                // width with a nickname and a rating in it already.
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

    /// "5 minutes ago", "yesterday", "3 weeks ago" — in the reader's language.
    /// Green for somebody on screen now, amber for somebody in a game, grey
    /// for everybody else — how long ago they were seen is written beside it.
    private var dot: Color {
        switch app.boards.presence[player.id] {
        case .looking, .online: Theatre.good
        case .playing: Theatre.brassHot
        case nil: Theatre.ivoryFaint.opacity(0.45)
        }
    }

    private var seen: String {
        guard player.lastSeen > .distantPast else { return L.t("online.playedRecently", "Played recently") }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter.localizedString(for: min(player.lastSeen, Date()), relativeTo: Date())
    }
}

/// "3 players are looking for a 5 min game right now", when anybody is.
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

private struct Rule: View {
    var body: some View {
        Rectangle().fill(Theatre.ruleSoft).frame(height: 1).padding(.horizontal, 8)
    }
}

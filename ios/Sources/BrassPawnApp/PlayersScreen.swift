import ChessTraining
import SwiftUI

/// Everybody who plays Brass Pawn online, by their Game Center nickname: the
/// rank list for a clock, and who has been about this week and who has not —
/// each with an invitation a tap away, so a game with somebody particular is
/// not a link sent through Messages and a wait.
struct PlayersScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State var clock: TimeControl
    @State private var list: Shown = .ranks
    /// Invite a player to a game on a clock. The screen goes, and the lobby
    /// shows the invitation going out.
    let onInvite: (BoardPlayer, TimeControl) -> Void

    enum Shown: Hashable { case ranks, players }

    private var boards: OnlineBoards { app.boards }

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("online.players", "Players"),
                                  subtitle: L.t("online.gameCenter", "Game Center")) { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    BrassSegmentedPicker(L.t("online.players", "Players"), selection: $list,
                                         options: [.ranks, .players]) { option in
                        Text(option == .ranks ? L.t("online.rankList", "Rank list") : L.t("online.players", "Players"))
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

                    if !boards.hasLoaded && boards.isLoading {
                        HStack(spacing: 9) {
                            BrassActivityIndicator(size: 15)
                            Text(L.t("online.loadingPlayers", "Reading the lists from Game Center…"))
                                .appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else if list == .ranks {
                        ranks
                    } else {
                        players
                    }

                    Text(L.t("online.friendlyNote", "Invitations and rematches are friendly games, and only one game a day against the same opponent is rated: a place on the list is won against whoever the search finds."))
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
                        .padding(.top, 6)
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

    // MARK: - The rank list

    @ViewBuilder
    private var ranks: some View {
        let entries = boards.ranks[clock] ?? []
        if let me = boards.mine[clock], let rank = me.rank {
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
            empty(L.t("online.nobodyRanked", "Nobody has a rating on this clock yet. The first game played on it starts the list."))
        } else {
            Panel(padding: 6) {
                ForEach(entries) { player in
                    PlayerRow(player: player, showsRank: true, invite: invite(player))
                    if player.id != entries.last?.id { Rule() }
                }
            }
        }
    }

    // MARK: - Active and not

    @ViewBuilder
    private var players: some View {
        let online = boards.onlineNow()
        let active = boards.active()
        let inactive = boards.inactive()
        if online.isEmpty && active.isEmpty && inactive.isEmpty {
            empty(L.t("online.nobodyYet", "Nobody else has played online yet. Invite somebody with a link from the lobby."))
        }
        if !online.isEmpty {
            Slug(text: L.t("online.presence.online", "Online now") + " · \(online.count)")
                .padding(.horizontal, 4)
            Panel(padding: 6) {
                ForEach(online) { player in
                    PlayerRow(player: player, showsRank: false, invite: invite(player))
                    if player.id != online.last?.id { Rule() }
                }
            }
        }
        if !active.isEmpty {
            Slug(text: L.t("online.activeThisWeek", "Active this week") + " · \(active.count)")
                .padding(.horizontal, 4)
                .padding(.top, online.isEmpty ? 0 : 6)
            Panel(padding: 6) {
                ForEach(active) { player in
                    PlayerRow(player: player, showsRank: false, invite: invite(player))
                    if player.id != active.last?.id { Rule() }
                }
            }
        }
        if !inactive.isEmpty {
            Slug(text: L.t("online.notSeenThisWeek", "Not seen this week") + " · \(inactive.count)")
                .padding(.horizontal, 4)
                .padding(.top, 6)
            Panel(padding: 6) {
                ForEach(inactive) { player in
                    PlayerRow(player: player, showsRank: false, invite: invite(player))
                    if player.id != inactive.last?.id { Rule() }
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
                Text(verbatim: player.alias)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
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
    /// Bright for somebody on screen now, green for this week, faint otherwise.
    private var dot: Color {
        switch app.boards.presence[player.id] {
        case .looking, .online: Theatre.brassHot
        case .playing: Theatre.good
        case nil: player.isActive() ? Theatre.good.opacity(0.7) : Theatre.ivoryFaint.opacity(0.45)
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

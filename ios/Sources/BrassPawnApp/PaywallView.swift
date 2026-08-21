import ChessTraining
import StoreKit
import SwiftUI

/// The one screen that asks for money.
///
/// It appears when a free day's training runs out, never before — nobody buys
/// a trainer they have not used, and being asked on the way in is the fastest
/// way to be deleted. Everything Apple requires to be visible before a purchase
/// is on this screen rather than a tap away: what it costs, how long that
/// covers, that a subscription renews itself, and how to get out of it.
struct PaywallView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showsAbout = false
    /// What the player just ran out of, so the screen can say so.
    var activity: TrainingActivity?

    private var store: SubscriptionStore { app.store }

    var body: some View {
        VStack(spacing: 0) {
            BrassNavigationHeader(title: L.t("store.title", "Brass Pawn Pro")) { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    included
                    products
                    footer
                }
                .padding(18)
            }
        }
        .background(Theatre.ink.ignoresSafeArea())
        .task { await store.prepare() }
        .onChange(of: store.isPro) { _, isPro in if isPro { dismiss() } }
        .fullScreenCover(isPresented: $showsAbout) { AboutScreen() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(runOutText).font(.title3.weight(.semibold))
            Text(L.t("store.freeForever", "Playing stays free — against the engine and against people, with no limit and no adverts. What Pro unlocks is the training."))
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var runOutText: String {
        guard let activity else { return L.t("store.unlockTraining", "Unlock the training") }
        return switch activity {
        case .tactics: L.t("store.outOfPuzzles", "That is today's five puzzles.")
        case .rush: L.t("store.outOfRush", "That is today's Rush run.")
        case .positional: L.t("store.outOfPositional", "That is today's three positional exercises.")
        case .endgame: L.t("store.outOfEndgames", "That is today's three endgame drills.")
        case .guessTheElo: L.t("store.outOfGuess", "That is today's three games to judge.")
        }
    }

    private var included: some View {
        Card {
            row("infinity", L.t("store.unlimitedPuzzles", "Every one of the 14,351 puzzles, as many a day as you want"))
            row("timer", L.t("store.unlimitedRush", "Rush runs without a daily limit"))
            row("square.grid.3x3.middle.filled", L.t("store.unlimitedRest", "Positional judgement, endgame drills and Guess the Elo, unlimited"))
            row("nosign", L.t("store.noAds", "No adverts, in any part of the app, ever"))
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).frame(width: 22).foregroundStyle(.tint)
            Text(text).font(.subheadline)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var products: some View {
        if store.monthly == nil, store.lifetime == nil, store.hasAttemptedLoad {
            Button(L.t("store.tryAgain", "Try again")) { Task { await store.loadProducts() } }
                .buttonStyle(PillButtonStyle(emphasis: .ghost))
        } else if store.monthly == nil && store.lifetime == nil {
            HStack(spacing: 8) {
                BrassActivityIndicator(size: 15)
                Text(L.t("store.loadingPrices", "Loading prices…")).font(.footnote).foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 10) {
                if let monthly = store.monthly {
                    button(for: monthly,
                           title: L.t("store.monthly", "Monthly"),
                           detail: L.t("store.perMonth", "%@ per month, renews automatically", monthly.displayPrice),
                           prominent: true)
                }
                if let lifetime = store.lifetime {
                    button(for: lifetime,
                           title: L.t("store.lifetime", "One-off unlock"),
                           detail: L.t("store.onceOnly", "%@ once. No subscription, no renewal.", lifetime.displayPrice),
                           prominent: false)
                }
            }
        }

        if let message = store.message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(store.messageIsError ? Color.red : Color.secondary)
        }
    }

    private func button(for product: Product, title: String, detail: String, prominent: Bool) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title).font(Face.display(22))
                    Spacer()
                    Text(product.displayPrice).font(Face.display(22)).monospacedDigit()
                }
                Text(detail).font(.caption).foregroundStyle(prominent ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .buttonStyle(.plain)
        .background(
            prominent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.4)),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .foregroundStyle(prominent ? Color.white : Color.primary)
        .disabled(store.isBusy)
        .opacity(store.isBusy ? 0.6 : 1)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Required in the app itself, not only in the App Store listing.
            Text(L.t("store.renewalTerms", "The monthly plan renews each month until you cancel it. Cancel any time in Settings › Apple Account › Subscriptions, at least a day before it renews. The one-off unlock is a single payment and never renews."))
                .font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Button(L.t("store.restore", "Restore purchases")) { Task { await store.restore() } }
                if store.monthly != nil {
                    Button(L.t("store.manage", "Manage subscription")) { Task { await store.manageSubscriptions() } }
                }
            }
            .font(.footnote)
            .disabled(store.isBusy)

            HStack(spacing: 14) {
                BrassLinkButton(title: L.t("store.terms", "Terms of Use"), destination: AboutScreen.termsURL)
                BrassLinkButton(title: L.t("store.privacy", "Privacy Policy"), destination: AboutScreen.privacyURL)
            }
            .font(.footnote)

            Button { showsAbout = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text")
                    Text(L.t("settings.about", "About & licence"))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(Theatre.ivory)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

/// The row that keeps the offer visible without nagging: one line in Progress,
/// where somebody looking at their rating is already thinking about improving.
struct ProUpsellRow: View {
    @Environment(AppModel.self) private var app
    @State private var showsPaywall = false

    var body: some View {
        if app.store.isPro {
            HStack {
                Text(L.t("store.title", "Brass Pawn Pro"))
                Spacer()
                Text(L.t("store.active", "Active"))
                    .foregroundStyle(Theatre.brass)
            }
            .font(.subheadline)
        } else {
            Button { showsPaywall = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t("store.title", "Brass Pawn Pro")).font(.body)
                        Text(L.t("store.upsell", "Unlimited puzzles, drills and runs"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showsPaywall) { PaywallView() }
        }
    }
}

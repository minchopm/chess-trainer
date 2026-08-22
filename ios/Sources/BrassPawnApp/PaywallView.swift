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
    @Environment(\.openURL) private var openURL
    @State private var showsAbout = false
    @State private var selectedOffer: Offer = .monthly
    /// What the player just ran out of, so the screen can say so.
    var activity: TrainingActivity?

    private var store: SubscriptionStore { app.store }

    private enum Offer {
        case monthly
        case lifetime
    }

    var body: some View {
        VStack(spacing: 0) {
            purchasesHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    offerCard
                    planPicker
                    purchaseAction
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

    private var purchasesHeader: some View {
        VStack(spacing: 2) {
            Text(L.t("store.purchases", "Purchases"))
                .appFont(size: 20, weight: .semibold)
                .foregroundStyle(Theatre.ivory)
            Text(L.t("store.headerSubtitle", "Unlimited training"))
                .appFont(.caption)
                .foregroundStyle(Theatre.ivoryDim)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 54)
        .overlay(alignment: .leading) {
            BrassBackButton { dismiss() }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Theatre.ink.opacity(0.96))
    }

    private var runOutText: String {
        guard let activity else { return L.t("store.unlockTraining", "Unlock the training") }
        return switch activity {
        // No counts in the words. The number lives in `dailyFreeLimit` and is
        // shown from it; spelled out here it goes stale the moment the limit
        // changes, and it did — the copy said five while the limit was one.
        case .tactics: L.t("store.doneTactics", "Today's free Tactics puzzles are done.")
        case .rush: L.t("store.doneRush", "Today's free Rush runs are done.")
        case .positional: L.t("store.donePositional", "Today's free positional exercises are done.")
        case .endgame: L.t("store.doneEndgames", "Today's free endgame drills are done.")
        case .guessTheElo: L.t("store.doneGuess", "Today's free games to judge are done.")
        }
    }

    private var offerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(runOutText)
                        .appFont(.title3, weight: .semibold)
                        .foregroundStyle(Theatre.ivory)
                    Text(selectedOffer == .monthly
                         ? L.t("store.monthlyPlan", "Monthly Pro plan")
                         : L.t("store.lifetimePlan", "One-off lifetime unlock"))
                        .appFont(.caption)
                        .foregroundStyle(Theatre.ivoryDim)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(selectedProduct?.displayPrice ?? "—")
                        .appFont(.title2, weight: .semibold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)
                        .foregroundStyle(Theatre.brassHot)
                    Text(selectedOffer == .monthly
                         ? L.t("store.perMonthShort", "per month")
                         : L.t("store.onceShort", "once"))
                        .appFont(.caption2)
                        .foregroundStyle(Theatre.ivoryDim)
                }
            }

            Rectangle()
                .fill(Theatre.ruleSoft)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 12) {
                row("infinity", L.t("store.unlimitedPuzzles", "All 14,351 puzzles, without a daily limit"))
                row("timer", L.t("store.unlimitedRush", "Rush runs without a daily limit"))
                row("square.grid.3x3.middle.filled", L.t("store.unlimitedRest", "Unlimited positional, endgame and Guess the Elo training"))
            }
        }
        .padding(16)
        .background {
            BrassPlateShape(cut: 14).fill(LinearGradient(
                colors: [Theatre.ink4, Theatre.ink2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
        .overlay {
            BrassPlateShape(cut: 14)
                .strokeBorder(Theatre.brassDeep.opacity(0.62), lineWidth: 0.85)
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrassIcon(symbol, size: 22).foregroundStyle(Theatre.brass)
            Text(text)
                .appFont(.subheadline)
                .foregroundStyle(Theatre.ivory)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var planPicker: some View {
        if store.monthly == nil, store.lifetime == nil, store.hasAttemptedLoad {
            EmptyView()
        } else if store.monthly == nil && store.lifetime == nil {
            HStack(spacing: 8) {
                BrassActivityIndicator(size: 15)
                Text(L.t("store.loadingPrices", "Loading prices…")).appFont(.footnote).foregroundStyle(Theatre.ivoryDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } else {
            VStack(spacing: 10) {
                if let monthly = store.monthly {
                    planOption(
                        .monthly,
                        title: L.t("store.monthly", "Monthly"),
                        detail: L.t("store.renews", "Renews automatically"),
                        price: monthly.displayPrice
                    )
                }
                if let lifetime = store.lifetime {
                    planOption(
                        .lifetime,
                        title: L.t("store.lifetime", "One-off"),
                        detail: L.t("store.noRenewal", "No renewal"),
                        price: lifetime.displayPrice
                    )
                }
            }
            .onAppear { normaliseSelectedOffer() }
            .onChange(of: store.monthly?.id) { _, _ in normaliseSelectedOffer() }
            .onChange(of: store.lifetime?.id) { _, _ in normaliseSelectedOffer() }
        }
    }

    @ViewBuilder
    private var purchaseAction: some View {
        if store.monthly == nil, store.lifetime == nil, store.hasAttemptedLoad {
            Button {
                Task { await store.loadProducts() }
            } label: {
                Text(L.t("store.tryAgain", "Try again"))
                    .appFont(size: 12, weight: .semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SubscriptionActionButtonStyle(prominent: false))
        } else if let product = selectedProduct {
            Button {
                Task { await store.purchase(product) }
            } label: {
                HStack(spacing: 9) {
                    if store.isBusy {
                        BrassActivityIndicator(size: 15)
                    }
                    Text(selectedOffer == .monthly
                         ? L.t("store.subscribe", "Subscribe")
                         : L.t("store.unlock", "Unlock forever"))
                    Spacer()
                    Text(product.displayPrice).monospacedDigit()
                }
                .appFont(size: 12, weight: .semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SubscriptionActionButtonStyle(prominent: true, enabled: !store.isBusy))
            .disabled(store.isBusy)
        }

        if let message = store.message {
            Text(message)
                .appFont(.footnote)
                .foregroundStyle(store.messageIsError ? Theatre.bad : Theatre.ivoryDim)
        }
    }

    private func planOption(_ offer: Offer, title: String, detail: String, price: String) -> some View {
        let selected = selectedOffer == offer
        return Button {
            withAnimation(.easeOut(duration: 0.18)) { selectedOffer = offer }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .appFont(size: 10, weight: .semibold)
                    .tracking(0.8)
                    .textCase(.uppercase)
                Text(price)
                    .appFont(size: 18, weight: .semibold)
                    .monospacedDigit()
                Text(detail).appFont(.caption2).foregroundStyle(Theatre.ivoryDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .buttonStyle(BrassPressStyle())
        .background {
            BrassPlateShape(cut: 9).fill(LinearGradient(
                colors: selected ? [Theatre.ink4, Theatre.ink2] : [Theatre.ink3, Theatre.ink2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
        .overlay {
            BrassPlateShape(cut: 9)
                .strokeBorder(selected ? Theatre.brassHot.opacity(0.82) : Theatre.brassDeep.opacity(0.42), lineWidth: 0.85)
        }
        .shadow(color: selected ? Theatre.brassGlow : .clear, radius: 8, y: 2)
        .foregroundStyle(selected ? Theatre.brassHot : Theatre.ivory)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Required in the app itself, not only in the App Store listing.
            Text(L.t("store.renewalTerms", "The monthly plan renews each month until you cancel it. Cancel any time in Settings › Apple Account › Subscriptions, at least a day before it renews. The one-off unlock is a single payment and never renews."))
                .appFont(.caption).foregroundStyle(Theatre.ivoryDim)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                footerAction("arrow.counterclockwise", L.t("store.restore", "Restore purchases")) {
                    Task { await store.restore() }
                }
                footerAction("creditcard", L.t("store.manage", "Manage subscription")) {
                    Task { await store.manageSubscriptions() }
                }
                footerAction("lock.shield", L.t("store.privacy", "Privacy Policy")) {
                    openURL(AboutScreen.privacyURL)
                }
                footerAction("doc.text", L.t("store.terms", "Terms of Use")) {
                    openURL(AboutScreen.termsURL)
                }
            }
            .disabled(store.isBusy)

            Button { showsAbout = true } label: {
                HStack(spacing: 10) {
                    BrassIcon("doc.text", size: 19)
                    Text(L.t("settings.about", "About & licence"))
                    Spacer()
                    Image(systemName: "chevron.forward")
                }
                .appFont(.subheadline)
                .foregroundStyle(Theatre.ivory)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background {
                    BrassPlateShape(cut: 9).fill(Theatre.ink3)
                }
                .overlay {
                    BrassPlateShape(cut: 9)
                        .strokeBorder(Theatre.brassDeep.opacity(0.48), lineWidth: 0.7)
                }
            }
            .buttonStyle(BrassPressStyle())
        }
    }

    private var selectedProduct: Product? {
        switch selectedOffer {
        case .monthly:
            store.monthly ?? store.lifetime
        case .lifetime:
            store.lifetime ?? store.monthly
        }
    }

    private func normaliseSelectedOffer() {
        if selectedOffer == .monthly, store.monthly == nil, store.lifetime != nil {
            selectedOffer = .lifetime
        } else if selectedOffer == .lifetime, store.lifetime == nil, store.monthly != nil {
            selectedOffer = .monthly
        }
    }

    private func footerAction(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                BrassIcon(symbol, size: 18)
                    .foregroundStyle(Theatre.brass)
                Text(title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .appFont(.caption, weight: .medium)
            .foregroundStyle(Theatre.ivoryDim)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background {
                BrassPlateShape(cut: 7).fill(Theatre.ink2)
            }
            .overlay {
                BrassPlateShape(cut: 7)
                    .strokeBorder(Theatre.brassDeep.opacity(0.38), lineWidth: 0.6)
            }
        }
        .buttonStyle(BrassPressStyle())
    }
}

/// Keeps the subscription actions in the app's brass geometry without pulling
/// the display or mono faces into this screen. Store copy must remain equally
/// readable in every supported writing system.
private struct SubscriptionActionButtonStyle: ButtonStyle {
    var prominent: Bool
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(size: 12, weight: .semibold)
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(prominent ? Theatre.brassHot : Theatre.ivory)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                BrassPlateShape(cut: 10).fill(LinearGradient(
                    colors: prominent
                        ? [Theatre.ink4, Theatre.ink2]
                        : [Theatre.ink3, Theatre.ink2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
            .overlay {
                BrassPlateShape(cut: 10)
                    .strokeBorder(
                        prominent ? Theatre.brassHot.opacity(0.82) : Theatre.brassDeep.opacity(0.55),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: prominent ? Theatre.brassGlow : .clear, radius: 10, y: 3)
            .contentShape(BrassPlateShape(cut: 10))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
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
            .appFont(.subheadline)
        } else {
            Button { showsPaywall = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t("store.title", "Brass Pawn Pro")).appFont(.body)
                        Text(L.t("store.upsell", "Unlimited puzzles, drills and runs"))
                            .appFont(.caption).foregroundStyle(Theatre.ivoryDim)
                    }
                    Spacer()
                    Image(systemName: "chevron.forward").font(.caption).foregroundStyle(Theatre.ivoryFaint)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background {
                    BrassPlateShape(cut: 8).fill(Theatre.ink3)
                }
                .overlay {
                    BrassPlateShape(cut: 8)
                        .strokeBorder(Theatre.brassDeep.opacity(0.45), lineWidth: 0.65)
                }
            }
            .buttonStyle(BrassPressStyle())
            .fullScreenCover(isPresented: $showsPaywall) { PaywallView() }
        }
    }
}

import ChessTraining
import Foundation
import Observation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

/// What the app sells, and whether this person has bought it.
///
/// Three products: a month at a time for someone trying the trainer out, a
/// year for someone who means to stay and would rather pay once a year, and a
/// one-off unlock for someone who has decided. They are offered as a way of
/// supporting the app as much as of buying the training — Brass Pawn is open
/// source and has no ads, and this is what pays for it.
@MainActor
@Observable
public final class SubscriptionStore {
    public enum ProductID {
        public static let monthly = "com.artesoft.brasspawn.pro.monthly"
        public static let yearly = "com.artesoft.brasspawn.pro.yearly"
        public static let lifetime = "com.artesoft.brasspawn.pro.lifetime"
        public static let all = [monthly, yearly, lifetime]
    }

    public enum Activity: Equatable { case loading, purchasing, restoring, managing }

    /// True once anything on the list has been bought. The lifetime unlock and
    /// the two subscriptions grant exactly the same thing; nothing downstream
    /// needs to know which one paid for it.
    public private(set) var isPro = false
    public private(set) var isCheckingEntitlement = true
    public private(set) var monthly: Product?
    public private(set) var yearly: Product?
    public private(set) var lifetime: Product?
    public private(set) var activity: Activity?
    public private(set) var message: String?
    public private(set) var messageIsError = false
    /// Set once a load has finished, successfully or not, so the paywall can
    /// stop spinning and offer to try again instead.
    public private(set) var hasAttemptedLoad = false

    private var updates: Task<Void, Never>?

    public var isBusy: Bool { isCheckingEntitlement || activity != nil }

    public init() {
        updates = Task { [weak self] in
            // Purchases made on another device, renewals, refunds and family
            // sharing all arrive here rather than through a purchase call.
            for await result in Transaction.updates {
                guard !Task.isCancelled, case .verified(let transaction) = result,
                      ProductID.all.contains(transaction.productID) else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }

    /// Stop listening. The store lives as long as the app does, so this exists
    /// for tests rather than for teardown.
    public func stop() {
        updates?.cancel()
        updates = nil
    }

    public func prepare() async {
        await refreshEntitlement()
        await loadProducts()
    }

    public func refreshEntitlement() async {
        isCheckingEntitlement = true
        defer { isCheckingEntitlement = false }

        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  ProductID.all.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded
            else { continue }
            entitled = true
            break
        }
        isPro = entitled
    }

    public func loadProducts() async {
        guard monthly == nil || yearly == nil || lifetime == nil else { return }
        activity = .loading
        defer {
            activity = nil
            hasAttemptedLoad = true
        }

        do {
            let products = try await Product.products(for: ProductID.all)
            monthly = products.first { $0.id == ProductID.monthly }
            yearly = products.first { $0.id == ProductID.yearly }
            lifetime = products.first { $0.id == ProductID.lifetime }
            if monthly == nil, yearly == nil, lifetime == nil {
                show(L.t("store.unavailable", "The store is unavailable right now. Please try again."), error: true)
            }
        } catch {
            show(L.t("store.appStoreUnreachable", "Could not reach the App Store: %@", error.localizedDescription), error: true)
        }
    }

    public func purchase(_ product: Product) async {
        guard activity == nil, !isPro else { return }
        activity = .purchasing
        clear()
        defer { activity = nil }

        do {
            switch try await buy(product) {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    show(L.t("store.unverified", "That purchase could not be verified."), error: true)
                    return
                }
                await transaction.finish()
                await refreshEntitlement()
                if isPro {
                    show(L.t("store.thankYouSupport", "Thank you for supporting Brass Pawn — the training is unlocked."))
                }
            case .pending:
                show(L.t("store.pending", "The purchase is waiting for approval."))
            case .userCancelled:
                clear()
            @unknown default:
                show(L.t("store.unknownResult", "The App Store returned a result this app does not understand."), error: true)
            }
        } catch {
            // The App Store can take the payment and still report an error —
            // the sandbox does, now and then. What the account owns is the
            // answer, not what the call said.
            await refreshEntitlement()
            if isPro {
                show(L.t("store.thankYouSupport", "Thank you for supporting Brass Pawn — the training is unlocked."))
            } else {
                show(L.t("store.purchaseFailed", "Purchase failed: %@", error.localizedDescription), error: true)
            }
        }
    }

    /// The purchase, confirmed in the window the paywall is in. Left to find
    /// one itself, StoreKit guesses, and on an iPad or a Mac it can guess
    /// wrong and fail with "Unable to Complete Request".
    private func buy(_ product: Product) async throws -> Product.PurchaseResult {
        #if canImport(UIKit)
        if let scene = activeScene {
            return try await product.purchase(confirmIn: scene)
        }
        #endif
        return try await product.purchase()
    }

    #if canImport(UIKit)
    private var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
    #endif

    public func restore() async {
        guard activity == nil else { return }
        activity = .restoring
        show(L.t("store.checkingAccount", "Checking your Apple Account…"))
        defer { activity = nil }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            show(isPro
                 ? L.t("store.restored", "Restored. The training is unlocked.")
                 : L.t("store.nothingToRestore", "No purchase was found on this Apple Account."),
                 error: !isPro)
        } catch {
            show(L.t("store.restoreFailed", "Restore failed: %@", error.localizedDescription), error: true)
        }
    }

    public func manageSubscriptions() async {
        #if canImport(UIKit)
        guard activity == nil, let scene = activeScene else { return }

        activity = .managing
        defer { activity = nil }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            await refreshEntitlement()
        } catch {
            show(L.t("store.manageFailed", "Could not open subscription management: %@", error.localizedDescription), error: true)
        }
        #endif
    }

    private func clear() {
        message = nil
        messageIsError = false
    }

    private func show(_ text: String, error: Bool = false) {
        message = text
        messageIsError = error
    }
}

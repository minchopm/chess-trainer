import ChessTraining
import Foundation
import Observation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

/// What the app sells, and whether this person has bought it.
///
/// Two products rather than a tier list: a month at a time for someone trying
/// the trainer out, and a one-off unlock for someone who has decided. There is
/// no annual plan in between, because a third price is a third decision to make
/// at the moment the player wants to solve a puzzle.
@MainActor
@Observable
public final class SubscriptionStore {
    public enum ProductID {
        public static let monthly = "com.arte-soft.chesstrainer.pro.monthly"
        public static let lifetime = "com.arte-soft.chesstrainer.pro.lifetime"
        public static let all = [monthly, lifetime]
    }

    public enum Activity: Equatable { case loading, purchasing, restoring, managing }

    /// True once anything on the list has been bought. The lifetime unlock and
    /// the subscription grant exactly the same thing; nothing downstream needs
    /// to know which one paid for it.
    public private(set) var isPro = false
    public private(set) var isCheckingEntitlement = true
    public private(set) var monthly: Product?
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
        guard monthly == nil || lifetime == nil else { return }
        activity = .loading
        defer {
            activity = nil
            hasAttemptedLoad = true
        }

        do {
            let products = try await Product.products(for: ProductID.all)
            monthly = products.first { $0.id == ProductID.monthly }
            lifetime = products.first { $0.id == ProductID.lifetime }
            if monthly == nil, lifetime == nil {
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
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    show(L.t("store.unverified", "That purchase could not be verified."), error: true)
                    return
                }
                await transaction.finish()
                await refreshEntitlement()
                if isPro {
                    show(L.t("store.thankYou", "Thank you — the training is unlocked."))
                }
            case .pending:
                show(L.t("store.pending", "The purchase is waiting for approval."))
            case .userCancelled:
                clear()
            @unknown default:
                show(L.t("store.unknownResult", "The App Store returned a result this app does not understand."), error: true)
            }
        } catch {
            show(L.t("store.purchaseFailed", "Purchase failed: %@", error.localizedDescription), error: true)
        }
    }

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
        guard activity == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }

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

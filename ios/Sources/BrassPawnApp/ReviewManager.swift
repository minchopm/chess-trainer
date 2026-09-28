import Foundation
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

/// Requests the system's in-app App Store rating prompt after a played session.
/// The App Store decides whether to display it; this app also waits until the
/// player has finished a few things over a couple of days — a rating asked for
/// before anybody knows the app is one given about nothing — then 120 days
/// between requests, and only asks after activity followed by a menu return.
@MainActor
enum ReviewManager {
    private static let installDateKey = "rm_installDate"
    private static let createCountKey = "rm_createCount"
    private static let lastPromptKey = "rm_lastPromptDate"
    private static let cooldown: TimeInterval = 120 * 86_400
    /// Finished games, puzzles, drills or rated online games before the first ask.
    private static let eventsBeforeAsking = 3
    /// Days since the app was first opened before the first ask.
    private static let daysBeforeAsking: TimeInterval = 2 * 86_400
    private static var activitySinceMenu = false

    static func appLaunched() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: installDateKey) == nil {
            defaults.set(Date(), forKey: installDateKey)
        }
    }

    static func eventCreated() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: createCountKey) + 1, forKey: createCountKey)
        activitySinceMenu = true
    }

    @discardableResult
    static func tryRequestReview() -> Bool {
        guard activitySinceMenu else { return false }

        let defaults = UserDefaults.standard
        guard let installed = defaults.object(forKey: installDateKey) as? Date else { return false }
        let hasPlayedEnough = defaults.integer(forKey: createCountKey) >= eventsBeforeAsking
        let hasHadTheApp = Date().timeIntervalSince(installed) >= daysBeforeAsking
        guard hasPlayedEnough && hasHadTheApp else { return false }
        if let last = defaults.object(forKey: lastPromptKey) as? Date,
           Date().timeIntervalSince(last) < cooldown {
            activitySinceMenu = false
            return false
        }

        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return false }

        activitySinceMenu = false
        if #available(iOS 18, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
        defaults.set(Date(), forKey: lastPromptKey)
        defaults.set(0, forKey: createCountKey)
        return true
        #else
        return false
        #endif
    }
}

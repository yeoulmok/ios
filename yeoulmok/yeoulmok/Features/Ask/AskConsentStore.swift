import Foundation

/// Whether the user agreed that AI questions go to an outside AI service (#100).
/// App Store Review Guideline 5.1.2(i) (Nov 2025): an app must say so and get the
/// user's permission before sharing personal data with a third-party AI. Asked once,
/// before the first question; kept on this device.
final class AskConsentStore {
    static let key = "aiQuestionConsentGiven"

    /// The one the app uses. Mock runs (UI tests) get a fresh one each launch, set by
    /// `YeoulmokApp`, so every test starts without consent.
    static var shared = AskConsentStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// A store of its own that starts empty (tests, previews, mock runs).
    static func fresh() -> AskConsentStore {
        AskConsentStore(defaults: UserDefaults(suiteName: "AskConsent-\(UUID().uuidString)")!)
    }

    var isGiven: Bool {
        get { defaults.bool(forKey: Self.key) }
        set { defaults.set(newValue, forKey: Self.key) }
    }
}

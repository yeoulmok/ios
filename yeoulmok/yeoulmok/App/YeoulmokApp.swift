import SwiftUI

@main
struct YeoulmokApp: App {
    /// The one data source for the whole app. Screens receive it and never
    /// create their own, so switching to the real server (#8 and later)
    /// is a change in this one place.
    private let repository: any ValleyRepository = Self.makeRepository()

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository)
        }
    }

    private static func makeRepository() -> any ValleyRepository {
        do {
            return try MockValleyRepository(failsSubscriptionChanges: Self.launchedWith("-mockSubscriptionFails"))
        } catch {
            // The mock JSON ships inside the app, so this only fails if the build is broken.
            fatalError("Mock data is missing from the app bundle: \(error)")
        }
    }

    /// Launch options for UI tests and screenshots. Only DEBUG builds read them,
    /// so a release build can never be started in a broken mode.
    private static func launchedWith(_ option: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(option)
        #else
        return false
        #endif
    }
}

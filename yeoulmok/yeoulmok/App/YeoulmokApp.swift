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
            return try MockValleyRepository()
        } catch {
            // The mock JSON ships inside the app, so this only fails if the build is broken.
            fatalError("Mock data is missing from the app bundle: \(error)")
        }
    }
}

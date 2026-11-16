import SwiftUI

@main
struct YeoulmokApp: App {
    /// The one data source for the whole app. Screens receive it and never
    /// create their own, so the data source is chosen in this one place.
    private let repository: any ValleyRepository = Self.makeRepository()
    /// Last answers, for when the server cannot be reached (#16).
    private let cache = Self.makeCache()

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository, cache: cache, makeLocationPermission: {
                SystemLocationPermission(fixedLocation: Self.launchedWith("-mockLocation")
                    ? SystemLocationPermission.mockLocation : nil)
            })
        }
    }

    /// The app's Caches folder with the real server. Mock runs (UI tests) get an empty
    /// folder of their own each launch, so one test never sees another's saved data.
    private static func makeCache() -> ValleyCache {
        guard usesMockData else { return .standard() }
        return ValleyCache(directory: FileManager.default.temporaryDirectory
            .appending(path: "ValleyCache-\(UUID().uuidString)", directoryHint: .isDirectory))
    }

    /// The real server, except in DEBUG runs that ask for the bundled mock data:
    /// UI tests (`-useMockData`, `-mockSubscriptionFails`, `-mockLoadFailsOnce`,
    /// `-mockOfflineAfterFirstLoad`) and the unit tests' host app,
    /// so tests never depend on the server's data or register devices on it.
    private static func makeRepository() -> any ValleyRepository {
        if usesMockData {
            return makeMockRepository()
        }
        let client = APIClient(baseURL: AppConfig.apiBaseURL)
        let registrar = DeviceRegistrar(client: client, store: KeychainDeviceIDStore())
        return ServerValleyRepository(client: client, registrar: registrar)
    }

    private static var usesMockData: Bool {
        launchedWith("-useMockData") || launchedWith("-mockSubscriptionFails")
            || launchedWith("-mockLoadFailsOnce") || launchedWith("-mockOfflineAfterFirstLoad")
            || isUnitTestHost
    }

    private static func makeMockRepository() -> any ValleyRepository {
        do {
            return try MockValleyRepository(failsSubscriptionChanges: launchedWith("-mockSubscriptionFails"),
                                            failsFirstLoad: launchedWith("-mockLoadFailsOnce"),
                                            failsRepeatedLoads: launchedWith("-mockOfflineAfterFirstLoad"))
        } catch {
            // The mock JSON ships inside the app, so this only fails if the build is broken.
            fatalError("Mock data is missing from the app bundle: \(error)")
        }
    }

    /// True when this app was launched only to host the unit tests (yeoulmokTests).
    private static var isUnitTestHost: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
        #else
        return false
        #endif
    }

    /// Launch options for UI tests and screenshots. Only DEBUG builds read them,
    /// so a release build can never be started in a broken mode.
    /// `-mockLocation` fixes the nearby tab's location (`SystemLocationPermission.mockLocation`);
    /// the permission still comes from iOS.
    private static func launchedWith(_ option: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(option)
        #else
        return false
        #endif
    }
}

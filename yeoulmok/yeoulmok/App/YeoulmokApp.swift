import SwiftUI

@main
struct YeoulmokApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// The real server's device registration; `nil` in mock runs.
    private static let registrar: DeviceRegistrar? = makeRegistrar()
    /// The one data source for the whole app. Screens receive it and never
    /// create their own, so the data source is chosen in this one place.
    private let repository: any ValleyRepository = Self.makeRepository()
    /// Last answers, for when the server cannot be reached (#16).
    private let cache = Self.makeCache()
    /// First-launch notification screen (#22).
    private let onboardingStore = Self.makeOnboardingStore()

    init() {
        // #100: mock runs (UI tests) start without AI consent every launch.
        if Self.usesMockData { AskConsentStore.shared = .fresh() }
    }

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository, cache: cache, makeLocationPermission: {
                SystemLocationPermission(fixedLocation: Self.launchedWith("-mockLocation")
                    ? SystemLocationPermission.mockLocation : nil)
            }, onboardingStore: onboardingStore, pushRouter: appDelegate.pushRouter)
            .task {
                appDelegate.pushArrived = { [repository] in await repository.invalidateCache() }
                if let valleyID = Self.mockPushValleyID {
                    appDelegate.pushRouter.open(valleyID: valleyID)
                }
                // DEBUG `-mockCautionValleyID <id>`: as if a 주의 push arrived while open (#108).
                if let valleyID = Self.mockOption("-mockCautionValleyID") {
                    appDelegate.pushRouter.showNotice(valleyID: valleyID, title: "금대리 계곡 · 주의",
                                                      body: "상류에 비가 많이 오고 있어요")
                }
                if let valleyID = Self.mockOption("-mockAlarmValleyID") {
                    appDelegate.pushRouter.raiseAlarm(valleyID: valleyID, level: .danger, playsSound: false)
                }
                await connectPushTokens()
            }
        }
    }

    /// Sends the APNs token to the server whenever iOS gives one (#22). Runs once, when the
    /// first screen appears: before that no token can have been asked for.
    private func connectPushTokens() async {
        guard let registrar = Self.registrar else { return }
        let receiver = PushTokenReceiver(permission: SystemNotificationPermission()) { token in
            try await registrar.updatePushToken(token)
        }
        appDelegate.pushTokens = receiver
        await receiver.refreshOnLaunch()
    }

    /// DEBUG `-mockPushValleyID <id>`: acts as if a push for that valley was tapped at
    /// launch (UI tests cannot send pushes). Only the number after the option is read.
    private static var mockPushValleyID: Int? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-mockPushValleyID"),
              arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
        #else
        return nil
        #endif
    }

    /// DEBUG `-mockAlarmValleyID <id>`: as if a 위험 · 대피 push for that valley was tapped (#60).
    private static func mockOption(_ name: String) -> Int? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
        #else
        return nil
        #endif
    }

    /// Mock runs skip the notification screen, so UI tests start on the tabs; they ask
    /// for it with `-notificationOnboarding`, and `-resetNotificationOnboarding` shows it again.
    private static func makeOnboardingStore() -> NotificationOnboardingStore? {
        guard !usesMockData || launchedWith("-notificationOnboarding") else { return nil }
        let store = NotificationOnboardingStore()
        if launchedWith("-resetNotificationOnboarding") {
            store.reset()
        }
        return store
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
    /// `-mockOfflineAfterFirstLoad`, `-mockManyValleys`) and the unit tests' host app,
    /// so tests never depend on the server's data or register devices on it.
    ///
    /// The server's answers are kept for 60 s (#103). The mock runs are not wrapped:
    /// UI tests like `-mockOfflineAfterFirstLoad` need every load to reach the mock.
    private static func makeRepository() -> any ValleyRepository {
        // `registrar` is nil exactly when `usesMockData` is true.
        guard let registrar else { return makeMockRepository() }
        return CachingValleyRepository(wrapping: ServerValleyRepository(client: client, registrar: registrar))
    }

    /// One client and one registrar, shared by the repository and the push token.
    private static let client = APIClient(baseURL: AppConfig.apiBaseURL)

    private static func makeRegistrar() -> DeviceRegistrar? {
        guard !usesMockData else { return nil }
        return DeviceRegistrar(client: client, store: KeychainDeviceIDStore())
    }

    private static var usesMockData: Bool {
        launchedWith("-useMockData") || launchedWith("-mockSubscriptionFails")
            || launchedWith("-mockLoadFailsOnce") || launchedWith("-mockOfflineAfterFirstLoad")
            || launchedWith("-mockManyValleys") || isUnitTestHost
    }

    private static func makeMockRepository() -> any ValleyRepository {
        #if DEBUG
        do {
            return try MockValleyRepository(failsSubscriptionChanges: launchedWith("-mockSubscriptionFails"),
                                            failsFirstLoad: launchedWith("-mockLoadFailsOnce"),
                                            failsRepeatedLoads: launchedWith("-mockOfflineAfterFirstLoad"),
                                            failsQuestions: launchedWith("-mockAskFails"),
                                            // The real server's 126 valleys, a page every 0.6 s (#96).
                                            manyValleys: launchedWith("-mockManyValleys"),
                                            pageDelay: launchedWith("-mockManyValleys") ? .milliseconds(600) : .zero)
        } catch {
            // The mock JSON ships inside the app, so this only fails if the build is broken.
            fatalError("Mock data is missing from the app bundle: \(error)")
        }
        #else
        // Release builds have no mock data (#102), and `usesMockData` is only true in
        // DEBUG builds (launch options and the unit test host are read there only).
        fatalError("Mock data is only in DEBUG builds")
        #endif
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
    /// the permission still comes from iOS. `-notificationOnboarding` and
    /// `-resetNotificationOnboarding`: see `makeOnboardingStore()`.
    private static func launchedWith(_ option: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(option)
        #else
        return false
        #endif
    }
}

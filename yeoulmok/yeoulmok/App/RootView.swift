import SwiftUI

/// Top-level view: the bottom tab bar (홈 / 근처 / 검색).
///
/// Each tab has its own `NavigationStack`, so a screen pushed in one tab
/// (e.g. a valley detail opened from home) is still there after visiting
/// another tab. `TabView` keeps every tab's view alive, so `@State` inside
/// a tab (typed search text, scroll position) is kept as well.
struct RootView: View {
    /// Passed down to every screen that shows valley data.
    let repository: any ValleyRepository
    /// Last answers saved on the device, shown when the server cannot be reached (#16).
    var cache: ValleyCache? = nil
    /// Nearby tab's location permission (and location). Tests can fix the location.
    var makeLocationPermission: () -> any LocationPermission = { SystemLocationPermission() }
    /// Remembers the first-launch notification screen (#22). `nil` never shows it
    /// (previews, and mock runs unless they ask with `-notificationOnboarding`).
    var onboardingStore: NotificationOnboardingStore? = nil

    @State private var selectedTab: AppTab = .home
    /// Set when a button on the notification screen is pressed, to leave it.
    @State private var onboardingFinished = false

    var body: some View {
        if let onboardingStore, !onboardingStore.isDone, !onboardingFinished {
            NotificationOnboardingView(permission: SystemNotificationPermission(), store: onboardingStore) {
                onboardingFinished = true
            }
        } else {
            tabs
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    screen(for: tab)
                        // One rule for every tab: a ValleyRoute opens the alert detail.
                        .navigationDestination(for: ValleyRoute.self) { route in
                            ValleyDetailView(valleyID: route.valleyID, repository: repository, cache: cache)
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(repository: repository, cache: cache, onAddValley: { selectedTab = .search })
        case .nearby:
            NearbyView(repository: repository, cache: cache, permission: makeLocationPermission())
        case .search: SearchView(repository: repository)
        }
    }
}

#Preview {
    RootView(repository: try! MockValleyRepository())
}

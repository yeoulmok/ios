import SwiftUI

/// Top-level view: the bottom tab bar (홈 / 근처 / 검색).
///
/// Each tab has its own `NavigationStack`, so a screen pushed in one tab
/// (e.g. a valley detail opened from home) is still there after visiting
/// another tab. `TabView` keeps every tab's view alive, so `@State` inside
/// a tab (typed search text, scroll position) is kept as well.
struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    screen(for: tab)
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
        case .home: HomeView()
        case .nearby: NearbyView()
        case .search: SearchView()
        }
    }
}

#Preview {
    RootView()
}

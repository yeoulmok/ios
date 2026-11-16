import SwiftUI

/// Which tab is shown, and what is pushed in each tab's `NavigationStack`.
/// Kept apart from `RootView` so the push rule (APP-NOTI-02) can be unit tested.
struct TabNavigation {
    var selected: AppTab = .home
    private var paths: [AppTab: NavigationPath] = [:]

    func path(for tab: AppTab) -> NavigationPath {
        paths[tab] ?? NavigationPath()
    }

    mutating func setPath(_ path: NavigationPath, for tab: AppTab) {
        paths[tab] = path
    }

    /// A tapped push: show home with that valley's detail on top. Back goes to the
    /// subscribed list. A detail (or settings) already open on home is replaced, and the
    /// other tabs keep what they showed.
    mutating func openDetailFromPush(valleyID: Int) {
        selected = .home
        paths[.home] = NavigationPath([ValleyRoute(valleyID: valleyID)])
    }
}

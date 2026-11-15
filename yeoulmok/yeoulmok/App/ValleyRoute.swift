import Foundation

/// "Open the alert detail of this valley." Pushed onto a tab's `NavigationStack`.
/// `RootView` turns it into `ValleyDetailView` for every tab, so home (#6),
/// nearby (#15), search (#21), and push notifications (#20) all open detail the same way.
struct ValleyRoute: Hashable {
    let valleyID: Int
}

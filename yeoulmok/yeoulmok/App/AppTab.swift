import Foundation

/// Bottom tabs, declared in display order (Figma: 홈 / 근처 / 검색).
/// Code that needs to switch tabs (e.g. opening a push notification in #20)
/// refers to these cases instead of an index.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case nearby
    case search

    var id: Self { self }

    /// Label under the tab icon.
    var title: String {
        switch self {
        case .home: "홈"
        case .nearby: "근처"
        case .search: "검색"
        }
    }

    /// SF Symbol name for the tab icon.
    var systemImage: String {
        switch self {
        case .home: "house"
        case .nearby: "location"
        case .search: "magnifyingglass"
        }
    }
}

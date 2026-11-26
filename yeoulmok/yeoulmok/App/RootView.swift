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
    /// Tapped pushes waiting to open a valley's detail (#20). `nil` in previews.
    var pushRouter: PushRouter? = nil

    @State private var navigation = TabNavigation()
    /// The 주의 popup's sound (#108).
    @State private var noticeSound = NoticeSound()
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
        TabView(selection: $navigation.selected) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: path(for: tab)) {
                    screen(for: tab)
                        // One rule for every tab: a ValleyRoute opens the alert detail.
                        .navigationDestination(for: ValleyRoute.self) { route in
                            ValleyDetailView(valleyID: route.valleyID, repository: repository, cache: cache)
                        }
                        .navigationDestination(for: SettingsRoute.self) { _ in
                            SettingsView()
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        // `initial`: a push that launched the app is already waiting when the tabs appear
        // (also after the first-launch notification screen).
        .onChange(of: pushRouter?.pendingValleyID, initial: true) {
            if let valleyID = pushRouter?.take() {
                navigation.openDetailFromPush(valleyID: valleyID)
            }
        }
        // #108: a 주의 push while open asks to look, with its sound once.
        .alert(pushRouter?.notice?.title ?? "", isPresented: noticeBinding, presenting: pushRouter?.notice) { _ in
            Button(Self.noticeConfirm, role: .cancel) { pushRouter?.dismissNotice() }
            Button(Self.noticeOpenDetail) { pushRouter?.openNotice() }
        } message: { notice in
            Text(notice.body)
        }
        .onChange(of: pushRouter?.notice) { _, notice in
            if notice != nil { noticeSound.play() }
        }
        // #60: a 위험 · 대피 push covers everything until "확인했습니다".
        .fullScreenCover(item: alarmBinding) { alarm in
            AlarmView(alarm: alarm, repository: repository, cache: cache) {
                pushRouter?.confirmAlarm()
            }
        }
    }

    /// Temporary wording until QA.
    static let noticeConfirm = "확인"
    static let noticeOpenDetail = "상세 보기"

    private var noticeBinding: Binding<Bool> {
        Binding(get: { pushRouter?.notice != nil },
                set: { if !$0 { pushRouter?.dismissNotice() } })
    }

    private var alarmBinding: Binding<PushRouter.Alarm?> {
        Binding(get: { pushRouter?.alarm },
                set: { if $0 == nil { pushRouter?.confirmAlarm() } })
    }

    private func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(get: { navigation.path(for: tab) },
                set: { navigation.setPath($0, for: tab) })
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(repository: repository, cache: cache, location: makeLocationPermission(),
                     onAddValley: { navigation.selected = .search })
        case .nearby:
            NearbyView(repository: repository, cache: cache, permission: makeLocationPermission())
        case .search: SearchView(repository: repository)
        }
    }
}

#Preview {
    RootView(repository: try! MockValleyRepository())
}

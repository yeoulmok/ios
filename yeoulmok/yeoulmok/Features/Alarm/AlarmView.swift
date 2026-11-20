import SwiftUI

/// Full-screen alarm for a 위험 · 대피 push (APP-NOTI-04, #60). Not in Figma:
///
///     ⚠ 경보                         (fixed, temporary)
///     위험 예시 계곡
///     [위험]
///     물이 빠르게 불어날 수 있어요       (server summary)
///     수위 30분  ↑ +0.18m / 기준 0.10m
///     · 즉시 물에서 나오기             (server actions)
///     · 소지품을 챙겨 높은 곳으로 이동
///     [ 확인했습니다 ]                  (fixed, temporary)
///     판단 보조 정보이며 …              (disclaimer)
///
/// Every safety sentence comes from the server (summary, actions, disclaimer); the app
/// adds only the title and the button. "확인했습니다" closes it and opens the detail.
struct AlarmView: View {
    static let title = "경보"
    static let confirmTitle = "확인했습니다"

    let alarm: PushRouter.Alarm
    let onConfirm: () -> Void

    @State private var viewModel: ValleyDetailViewModel
    @State private var sound = AlarmSound()

    init(alarm: PushRouter.Alarm, repository: any ValleyRepository, cache: ValleyCache?,
         onConfirm: @escaping () -> Void) {
        self.alarm = alarm
        self.onConfirm = onConfirm
        _viewModel = State(initialValue: ValleyDetailViewModel(valleyID: alarm.valleyID,
                                                               repository: repository, cache: cache))
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(Self.title, systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                    content
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) { confirmButton }
        }
        .task {
            if alarm.playsSound { sound.start() }
            await viewModel.load()
        }
        .onDisappear { sound.stop() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().tint(.white)
        case let .loaded(detail):
            Text(detail.name)
                .font(.largeTitle.weight(.heavy))
            // White badge: the level's own color would vanish on the same background.
            Text(detail.level.title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(detail.level.badgeBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(.white, in: Capsule())
            Text(detail.summary)
                .font(.title2.weight(.bold))
                .accessibilityIdentifier("alarm.summary")
            if let water = detail.observations.first(where: { $0.kind == .waterRise30Min }) {
                HStack(spacing: 6) {
                    Text("수위 30분")
                    if let direction = ChangeDirection(water.value) {
                        Image(systemName: direction.symbol)
                            .accessibilityLabel(direction.title)
                    }
                    Text(ObservationFormat.shortValue(water)).fontWeight(.bold)
                    if let limit = ObservationFormat.shortThreshold(water) {
                        Text("/ 기준 \(limit)").opacity(0.8)
                    }
                }
                .font(.headline)
                .padding(12)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(detail.actions, id: \.self) { action in
                    Label(action, systemImage: "checkmark.circle.fill")
                        .font(.title3.weight(.semibold))
                }
            }
            Text(detail.disclaimer)
                .font(.footnote)
                .opacity(0.85)
        case let .failed(message):
            // The alarm still says what kind of push this was, even without details.
            Text(message).font(.headline)
        }
    }

    private var confirmButton: some View {
        Button {
            sound.stop()
            onConfirm()
        } label: {
            Text(Self.confirmTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(background)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .accessibilityIdentifier("alarm.confirm")
    }

    /// The level's color; 대피 until the detail is loaded (alarms are 위험 · 대피 only).
    private var background: Color {
        if case let .loaded(detail) = viewModel.state, detail.level.isUrgent {
            return detail.level.badgeBackground
        }
        return ValleyLevel.evacuate.badgeBackground
    }
}

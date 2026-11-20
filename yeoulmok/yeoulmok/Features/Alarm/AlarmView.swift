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
            // Red tint, the darkest backdrop in the app (#72).
            PhotoBackdrop(style: .alarm)
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
            if alarm.playsSound { sound.start(level: alarm.level) }
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
            HStack(alignment: .center, spacing: 10) {
                StatusBadge(level: detail.level, size: .large)
                Text(detail.summary)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("alarm.summary")
            }
            let tiles = Self.tileObservations(in: detail)
            if !tiles.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(tiles.enumerated()), id: \.offset) { _, observation in
                        MetricTile(
                            title: ObservationFormat.title(observation),
                            valueText: ObservationFormat.shortValue(observation),
                            thresholdText: ObservationFormat.shortThreshold(observation),
                            value: observation.value,
                            threshold: observation.threshold)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(ObservationFormat.accessibilityLabel(observation))
                    }
                }
            }
            if !detail.actions.isEmpty {
                // The server's actions, as they are and in order, numbered.
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(detail.actions.enumerated()), id: \.offset) { index, action in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(Theme.Text.label)
                                .accessibilityHidden(true)
                            Text(action)
                                .font(.title3.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard()
            }
            Text(detail.disclaimer)
                .font(.footnote)
                .foregroundStyle(Theme.Text.body)
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
                .primaryButtonLabel()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .accessibilityIdentifier("alarm.confirm")
    }

    /// 수위 then 강수, the two numbers that matter in a flood (#72).
    private static func tileObservations(in detail: ValleyDetail) -> [ValleyObservation] {
        [ObservationKind.waterRise30Min, .rainLastHour].compactMap { kind in
            detail.observations.first { $0.kind == kind }
        }
    }
}

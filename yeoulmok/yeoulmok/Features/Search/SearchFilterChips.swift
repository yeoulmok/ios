import SwiftUI

/// Province chips, and the chosen province's city chips under them when it has more
/// than one (APP-SRCH-04, #96). Each row scrolls sideways. Not in Figma yet.
///
///     [전체 126] [강원 111] [경기 1] [경남 1] …
///     [강원 전체] [횡성군 14] [인제군 13] …      ← only after choosing 강원
struct SearchFilterChips: View {
    let total: Int
    let provinces: [ValleyRegions.Province]
    let cities: [ValleyRegions.City]
    let filter: ValleyFilter
    let selectProvince: (String?) -> Void
    let selectCity: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            chipRow {
                chip("전체", count: total, isOn: filter.province == nil, id: "search.province.all") {
                    selectProvince(nil)
                }
                ForEach(provinces) { province in
                    chip(province.province, count: province.count, isOn: filter.province == province.province,
                         id: "search.province.\(province.province)") {
                        selectProvince(province.province)
                    }
                }
            }
            if let province = filter.province, !cities.isEmpty {
                chipRow {
                    chip("\(province) 전체", count: nil, isOn: filter.city == nil, id: "search.city.all") {
                        selectCity(nil)
                    }
                    ForEach(cities) { city in
                        chip(city.city, count: city.count, isOn: filter.city == city.city,
                             id: "search.city.\(city.city)") {
                            selectCity(city.city)
                        }
                    }
                }
            }
        }
    }

    private func chipRow(@ViewBuilder _ chips: () -> some View) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) { chips() }
                .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ title: String, count: Int?, isOn: Bool, id: String,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                if let count {
                    Text("\(count)").font(.footnote)
                        .foregroundStyle(isOn ? Theme.night.opacity(0.6) : Theme.Text.label)
                }
            }
            .foregroundStyle(isOn ? Theme.night : Theme.Text.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isOn ? Color.white : Color.white.opacity(0.12), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // VoiceOver: "강원, 111곳", selected or not. (A button already reads as one
        // element; wrapping it in `accessibilityElement` would hide it from tests.)
        .accessibilityLabel(count.map { "\(title), \($0)곳" } ?? title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

/// The end of the search list (#96): the next page coming, a failed page to try
/// again, or "N곳 모두 봤어요". Nothing when the server sent everything at once.
struct SearchListEnd: View {
    let viewModel: SearchViewModel

    static func allShown(_ count: Int) -> String { "\(count)곳 모두 봤어요" }
    static let loadingMore = "더 불러오는 중"
    static let loadMoreFailed = "더 불러오지 못했어요"

    var body: some View {
        Group {
            if viewModel.loadMoreFailed {
                Button {
                    Task { await viewModel.retryMore() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise").accessibilityHidden(true)
                        Text(Self.loadMoreFailed)
                        Text("다시 시도").underline()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.Text.body)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("search.loadMoreRetry")
            } else if viewModel.canLoadMore || viewModel.isLoadingMore {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.Text.body)
                    Text(Self.loadingMore)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.body)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("search.loadingMore")
                // Asks for the next page whenever this row is on screen and the list grew,
                // so a short page still fills the screen. In its own task: scrolling the
                // row away must not cancel a page that is on its way.
                .task(id: viewModel.valleys.count) {
                    Task { await viewModel.loadMore() }
                }
            } else if viewModel.hasLoadedAll {
                Text(Self.allShown(viewModel.valleys.count))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Text.label)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("search.allShown")
            }
        }
    }
}

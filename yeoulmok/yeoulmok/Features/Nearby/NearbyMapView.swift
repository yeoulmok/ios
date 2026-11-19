import MapKit
import SwiftUI

/// Map above the nearby list (APP-NEAR-03, #58). Shows the same valleys as the list,
/// each as its status badge, and "내 위치" where the distances were measured from.
/// Tapping a badge shows that valley's row at the bottom of the map; tapping the row
/// opens its detail. Tapping the same badge again hides the row.
///
/// The location never leaves the phone. The map pictures themselves come from Apple Maps.
struct NearbyMapView: View {
    static let height: CGFloat = 260

    let user: CLLocationCoordinate2D
    let valleys: [NearbyValley]

    @State private var position: MapCameraPosition
    @State private var selectedID: Int?

    init(user: CLLocationCoordinate2D, valleys: [NearbyValley]) {
        self.user = user
        self.valleys = valleys
        _position = State(initialValue: Self.startPosition(user: user, valleys: valleys))
    }

    var body: some View {
        Map(position: $position) {
            Annotation("내 위치", coordinate: user) {
                UserDot()
            }
            .annotationTitles(.hidden)

            ForEach(valleys) { nearby in
                Annotation(nearby.valley.name, coordinate: coordinate(of: nearby)) {
                    pin(for: nearby)
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .frame(height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
        .overlay(alignment: .bottom) {
            if let selected = valleys.first(where: { $0.id == selectedID }) {
                NavigationLink(value: ValleyRoute(valleyID: selected.id)) {
                    NearbyRow(nearby: selected, identifier: "nearby.map.card")
                }
                .buttonStyle(.plain)
                .padding(8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedID)
        // A refresh can bring a new location or new valleys: show them all again.
        .onChange(of: valleys) {
            position = Self.startPosition(user: user, valleys: valleys)
            if !valleys.contains(where: { $0.id == selectedID }) {
                selectedID = nil
            }
        }
        .accessibilityIdentifier("nearby.map")
    }

    private func pin(for nearby: NearbyValley) -> some View {
        Button {
            selectedID = selectedID == nearby.id ? nil : nearby.id
        } label: {
            StatusBadge(level: nearby.valley.level)
                .scaleEffect(selectedID == nearby.id ? 1.25 : 1)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        // VoiceOver: "금대리 계곡 주의".
        .accessibilityLabel("\(nearby.valley.name) \(nearby.valley.level.title)")
        .accessibilityIdentifier("nearby.map.pin.\(nearby.id)")
    }

    private func coordinate(of nearby: NearbyValley) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: nearby.valley.latitude, longitude: nearby.valley.longitude)
    }

    private static func startPosition(user: CLLocationCoordinate2D, valleys: [NearbyValley]) -> MapCameraPosition {
        let points = valleys.map { CLLocationCoordinate2D(latitude: $0.valley.latitude, longitude: $0.valley.longitude) }
        return .region(NearbyMapRegion.fitting(user: user, valleys: points))
    }
}

/// "내 위치": a blue dot like the one iOS uses, drawn by the app so it sits exactly
/// where the distances were measured from (see `NearbyViewModel.userLocation`).
private struct UserDot: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 14, height: 14)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.3), radius: 2)
            .accessibilityLabel("내 위치")
            .accessibilityIdentifier("nearby.map.user")
    }
}

#Preview {
    let valleys = try! MockData.valleyList().valleys
    let user = SystemLocationPermission.mockLocation
    NavigationStack {
        NearbyMapView(user: user, valleys: NearbyValleys.closest(to: user, in: valleys))
            .padding()
    }
}

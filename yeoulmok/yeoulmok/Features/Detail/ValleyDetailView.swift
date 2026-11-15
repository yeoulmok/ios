import SwiftUI

/// Alert detail (APP-04). Placeholder until #10–#13 build the real screen:
/// for now it only loads the valley name, to show the right valley was opened.
struct ValleyDetailView: View {
    let valleyID: Int
    let repository: any ValleyRepository

    @State private var name: String?

    var body: some View {
        Text("경보 상세")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                name = try? await repository.valleyDetail(id: valleyID).name
            }
    }
}

#Preview {
    NavigationStack {
        ValleyDetailView(valleyID: 1, repository: try! MockValleyRepository())
    }
}

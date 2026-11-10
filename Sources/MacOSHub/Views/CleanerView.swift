import HubCleaner
import HubCore
import SwiftUI

struct CleanerView: View {
    @State private var engine = CleanerEngine()
    @State private var selectedCategories = Set(CleanerCategory.allCases)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            categoryList
            actionBar
            if case .scanning(let p) = engine.phase {
                ProgressView("Scanning…", value: p)
            }
            if case .cleaning(let p) = engine.phase {
                ProgressView("Cleaning…", value: p)
            }
            if case .completed(let freed) = engine.phase {
                Label("Freed \(ByteCountFormat.string(freed))", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(HubTheme.successGreen)
            }
            if case .failed(let msg) = engine.phase {
                Text(msg).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("Smart Cleaner")
    }

    private var totalBytes: Int64 {
        engine.categoryResults.filter(\.isSelected).reduce(0) { $0 + $1.totalBytes }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ByteCountFormat.string(totalBytes))
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("Potentially reclaimable from selected safe categories")
                .foregroundStyle(.secondary)
        }
    }

    private var categoryList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(CleanerCategory.allCases) { cat in
                    let result = engine.categoryResults.first { $0.category == cat }
                    HubCard {
                        HStack(alignment: .top) {
                            Toggle(isOn: binding(for: cat, result: result)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cat.title).font(.headline)
                                    Text(cat.summary).font(.caption).foregroundStyle(.secondary)
                                    if let result {
                                        Text("\(result.items.count) items · \(ByteCountFormat.string(result.totalBytes))")
                                            .font(.caption2)
                                    }
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }
            }
        }
    }

    private func binding(for cat: CleanerCategory, result: CleanerCategoryResult?) -> Binding<Bool> {
        Binding(
            get: { result?.isSelected ?? cat.defaultSelected },
            set: { engine.toggleCategory(cat, selected: $0) }
        )
    }

    private var actionBar: some View {
        HStack {
            Button("Scan Mac") {
                Task { await engine.scan(categories: selectedCategories) }
            }
            .buttonStyle(.borderedProminent)
            .tint(HubTheme.accentPurple)
            Button("Clean Selected") {
                Task { await engine.cleanSelected() }
            }
            .disabled(totalBytes == 0)
            Button("Reset") { engine.reset() }
        }
    }
}

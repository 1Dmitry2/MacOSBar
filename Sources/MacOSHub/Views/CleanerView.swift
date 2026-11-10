import HubCleaner
import HubCore
import SwiftUI

struct CleanerView: View {
  @State private var engine = CleanerEngine()
  @State private var showConfirm = false
  @Bindable private var history = CleanerHistoryStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(LocalizedStringKey("cleaner.title"))
        .font(.largeTitle.bold())
      Text(LocalizedStringKey("cleaner.subtitle"))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack(alignment: .firstTextBaseline) {
        Text(ByteCountFormat.string(totalSelectedBytes))
          .font(.system(size: 40, weight: .bold, design: .rounded))
        Spacer()
        if let scan = history.record.lastScanDate {
          Text(scan.formatted(date: .abbreviated, time: .shortened))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      historyPanel
      categoryList
      actionBar
      progressSection
      Spacer(minLength: 0)
    }
    .padding(24)
    .alert(Text(LocalizedStringKey("cleaner.confirm.title")), isPresented: $showConfirm) {
      Button(role: .cancel, action: {}) { Text(LocalizedStringKey("action.cancel")) }
      Button(role: .destructive) {
        Task { await engine.cleanSelected() }
      } label: { Text(LocalizedStringKey("action.confirm")) }
    } message: {
      Text(LocalizedStringKey("cleaner.confirm.message"))
    }
  }

  private var totalSelectedBytes: Int64 {
    engine.categoryResults.filter(\.isSelected).reduce(0) { $0 + $1.totalBytes }
  }

  private var historyPanel: some View {
    HubCard {
      VStack(alignment: .leading, spacing: 6) {
        Text(LocalizedStringKey("cleaner.history"))
          .font(.headline)
        Text("Освобождено всего: \(ByteCountFormat.string(history.record.totalFreedBytes))")
          .font(.caption)
        if let clean = history.record.lastCleanDate {
          Text("Последняя очистка: \(clean.formatted()) · \(ByteCountFormat.string(history.record.lastFreedBytes))")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var categoryList: some View {
    ScrollView {
      VStack(spacing: 10) {
        ForEach(CleanerCategory.allCases) { cat in
          let result = engine.categoryResults.first { $0.category == cat }
          HubCard {
            Toggle(isOn: binding(for: cat, result: result)) {
              VStack(alignment: .leading, spacing: 4) {
                Text(cat.title)
                  .font(.headline)
                Text(cat.summary)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                if let result {
                  Text("\(result.items.count) · \(ByteCountFormat.string(result.totalBytes))")
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

  private func binding(for cat: CleanerCategory, result: CleanerCategoryResult?) -> Binding<Bool> {
    Binding(
      get: { result?.isSelected ?? cat.defaultSelected },
      set: { engine.toggleCategory(cat, selected: $0) }
    )
  }

  private var actionBar: some View {
    HStack {
      Button(String(localized: "cleaner.scan", bundle: .module)) {
        Task { await engine.scan(categories: Set(CleanerCategory.allCases)) }
      }
      .buttonStyle(.borderedProminent)
      .tint(HubTheme.accentPurple)

      Button(String(localized: "cleaner.cleanSelected", bundle: .module)) {
        showConfirm = true
      }
      .disabled(totalSelectedBytes == 0)
    }
  }

  @ViewBuilder
  private var progressSection: some View {
    switch engine.phase {
    case .scanning(let p):
      ProgressView(String(localized: "cleaner.scanning", bundle: .module), value: p)
    case .cleaning(let p):
      ProgressView(String(localized: "cleaner.cleaning", bundle: .module), value: p)
    case .completed(let freed):
      Label("Освобождено \(ByteCountFormat.string(freed))", systemImage: "checkmark.circle.fill")
        .foregroundStyle(HubTheme.successGreen)
    case .failed(let msg):
      Text(msg).foregroundStyle(.red)
    default:
      EmptyView()
    }
  }
}

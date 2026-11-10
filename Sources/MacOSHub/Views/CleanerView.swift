import HubCleaner
import HubCore
import SwiftUI

@MainActor
final class CleanerViewModel {
    let engine = CleanerEngine()
}

struct CleanerView: View {
    @State private var model = CleanerViewModel()
    @State private var showConfirm = false
    @Bindable private var history = CleanerHistoryStore.shared
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LText("cleaner.title")
                .font(.largeTitle.bold())
            LText("cleaner.subtitle")
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
        .confirmationDialog(
            L10n.tr("cleaner.confirm.title", locale: locale),
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.tr("action.confirm", locale: locale), role: .destructive) {
                Task { await model.engine.cleanSelected() }
            }
            Button(L10n.tr("action.cancel", locale: locale), role: .cancel) {}
        } message: {
            Text(L10n.tr("cleaner.confirm.message", locale: locale))
        }
    }

    private var totalSelectedBytes: Int64 {
        model.engine.categoryResults.filter(\.isSelected).reduce(0) { $0 + $1.totalBytes }
    }

    private var historyPanel: some View {
        HubCard {
            VStack(alignment: .leading, spacing: 6) {
                LText("cleaner.history").font(.headline)
                Text(L10n.tr("cleaner.history.total", locale: locale) + ": \(ByteCountFormat.string(history.record.totalFreedBytes))")
                    .font(.caption)
                if let clean = history.record.lastCleanDate {
                    Text(L10n.tr("cleaner.history.last", locale: locale) + ": \(clean.formatted()) · \(ByteCountFormat.string(history.record.lastFreedBytes))")
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
                    let result = model.engine.categoryResults.first { $0.category == cat }
                    HubCard {
                        Toggle(isOn: binding(for: cat, result: result)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.tr(cat.localizationKey, locale: locale)).font(.headline)
                                Text(L10n.tr(cat.summaryKey, locale: locale))
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
            set: { model.engine.toggleCategory(cat, selected: $0) }
        )
    }

    private var actionBar: some View {
        HStack {
            Button(L10n.tr("cleaner.scan", locale: locale)) {
                Task { await model.engine.scan(categories: Set(CleanerCategory.allCases)) }
            }
            .buttonStyle(.borderedProminent)
            .tint(HubTheme.accentPurple)

            Button(L10n.tr("cleaner.cleanSelected", locale: locale)) {
                showConfirm = true
            }
            .disabled(totalSelectedBytes == 0)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        switch model.engine.phase {
        case .scanning(let p):
            ProgressView(L10n.tr("cleaner.scanning", locale: locale), value: p)
        case .cleaning(let p):
            ProgressView(L10n.tr("cleaner.cleaning", locale: locale), value: p)
        case .completed(let freed):
            Label(L10n.tr("cleaner.freed", locale: locale) + " \(ByteCountFormat.string(freed))", systemImage: "checkmark.circle.fill")
                .foregroundStyle(HubTheme.successGreen)
        case .failed(let msg):
            Text(msg).foregroundStyle(.red)
        default:
            EmptyView()
        }
    }
}

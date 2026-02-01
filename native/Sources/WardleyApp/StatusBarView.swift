import SwiftUI
import WardleyModel
import WardleyTheme

/// Bottom status bar showing file info, theme picker, and actions.
public struct StatusBarView: View {
    @Bindable var state: MapEnvironmentState
    var onExport: () -> Void
    var onStop: () -> Void
    var onReload: () -> Void

    public init(
        state: MapEnvironmentState,
        onExport: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onReload: @escaping () -> Void
    ) {
        self.state = state
        self.onExport = onExport
        self.onStop = onStop
        self.onReload = onReload
    }

    public var body: some View {
        HStack(spacing: 12) {
            // File info
            if let url = state.fileURL {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(url.lastPathComponent)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            if let modified = state.lastModified {
                Text("Modified: \(modified, format: .dateTime.hour().minute().second())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !state.parsedMap.errors.isEmpty {
                Label("\(state.parsedMap.errors.count) error(s)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // Unsaved changes indicator
            if state.hasUnsavedChanges {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            // Auto-save toggle
            Toggle(isOn: $state.autoSaveEnabled) {
                Label("Auto-save", systemImage: "arrow.triangle.2.circlepath")
            }
            .toggleStyle(.button)
            .font(.caption)
            .controlSize(.small)

            // Save button
            Button("Save", systemImage: "square.and.arrow.down") {
                state.saveToDisk()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .disabled(!state.hasUnsavedChanges)

            // Actions
            Button("Export PNG", systemImage: "square.and.arrow.up") {
                onExport()
            }
            .font(.caption)
            .buttonStyle(.bordered)

            Button("Reload", systemImage: "arrow.clockwise") {
                onReload()
            }
            .font(.caption)
            .buttonStyle(.bordered)

            Button("Stop", systemImage: "stop.fill") {
                onStop()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

import SwiftUI
import UniformTypeIdentifiers

/// Welcome screen with recent files and Open button.
public struct WelcomeView: View {
    @Bindable var state: MapEnvironmentState
    var recentFiles: RecentFilesService
    var onFileOpened: (URL) -> Void

    public init(
        state: MapEnvironmentState,
        recentFiles: RecentFilesService,
        onFileOpened: @escaping (URL) -> Void
    ) {
        self.state = state
        self.recentFiles = recentFiles
        self.onFileOpened = onFileOpened
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Wardley Maps")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Open a .owm file to preview. Edit in your favourite editor — changes appear live.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Open File...") {
                openFile()
            }
            .keyboardShortcut("o")
            .controlSize(.large)

            if !recentFiles.recentFiles.isEmpty {
                Divider()
                    .frame(maxWidth: 300)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Files")
                        .font(.headline)
                        .padding(.bottom, 4)

                    ForEach(recentFiles.recentFiles, id: \.self) { url in
                        Button {
                            onFileOpened(url)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                    Text(url.deletingLastPathComponent().path)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: 400, alignment: .leading)
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.wardleyMap, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            onFileOpened(url)
        }
    }
}

import Foundation

/// Watches a file for external modifications using kernel-level file system events.
@MainActor
public final class FileMonitorService {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.wardleymaps.filemonitor")
    private var watchedURL: URL?

    public var onFileChanged: (@MainActor () -> Void)?

    public init() {}

    public func watch(url: URL) {
        stop()
        watchedURL = url
        startWatching(url: url)
    }

    public func stop() {
        source?.cancel()  // cancel handler closes the fd
        source = nil
        fileDescriptor = -1
        watchedURL = nil
    }

    private func startWatching(url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File might not exist yet (rename in progress), retry shortly
            let u = url
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, self.watchedURL == u else { return }
                self.startWatching(url: u)
            }
            return
        }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.onFileChanged?()

                // Editors (vim, etc.) do atomic save: write tmp + rename.
                // After rename/delete the fd is stale — re-watch the path.
                if let url = self.watchedURL {
                    self.source?.cancel()  // cancel handler closes old fd
                    self.source = nil
                    self.fileDescriptor = -1
                    self.startWatching(url: url)
                }
            }
        }

        src.setCancelHandler {
            close(fd)
        }

        self.source = src
        src.resume()
    }
}

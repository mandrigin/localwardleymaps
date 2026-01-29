import Foundation

/// Watches a file for external modifications using kernel-level file system events.
///
/// All callbacks fire on an unspecified queue. Callers must hop to MainActor themselves.
public final class FileMonitorService: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.wardleymaps.filemonitor")

    // Mutable state protected by a lock
    private let lock = NSLock()
    private var _source: DispatchSourceFileSystemObject?
    private var _fileDescriptor: Int32 = -1
    private var _watchedURL: URL?
    private var _onFileChanged: (@Sendable () -> Void)?

    public init() {}

    public func watch(url: URL, onChange: @escaping @Sendable () -> Void) {
        stop()
        lock.lock()
        _watchedURL = url
        _onFileChanged = onChange
        lock.unlock()
        startWatching(url: url)
    }

    public func stop() {
        lock.lock()
        _source?.cancel()  // cancel handler closes fd
        _source = nil
        _fileDescriptor = -1
        _watchedURL = nil
        _onFileChanged = nil
        lock.unlock()
    }

    private func startWatching(url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File might not exist yet (atomic rename in progress), retry
            queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.lock.lock()
                let stillWatching = self._watchedURL == url
                self.lock.unlock()
                if stillWatching {
                    self.startWatching(url: url)
                }
            }
            return
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let callback = self._onFileChanged
            let watchedURL = self._watchedURL
            // Tear down old source — fd closed by cancel handler
            self._source?.cancel()
            self._source = nil
            self._fileDescriptor = -1
            self.lock.unlock()

            // Notify caller (caller is responsible for actor hopping)
            callback?()

            // Re-watch (editors do atomic save: write tmp + rename)
            if let url = watchedURL {
                self.queue.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.startWatching(url: url)
                }
            }
        }

        src.setCancelHandler {
            close(fd)
        }

        lock.lock()
        _source = src
        _fileDescriptor = fd
        lock.unlock()

        src.resume()
    }
}

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
    private var _generation: UInt64 = 0

    public init() {}

    deinit { stop() }

    public func watch(url: URL, onChange: @escaping @Sendable () -> Void) {
        stop()
        lock.lock()
        _watchedURL = url
        _onFileChanged = onChange
        let generation = _generation
        lock.unlock()
        startWatching(url: url, generation: generation)
    }

    public func stop() {
        lock.lock()
        _generation &+= 1
        _source?.cancel()  // cancel handler closes fd
        _source = nil
        _fileDescriptor = -1
        _watchedURL = nil
        _onFileChanged = nil
        lock.unlock()
    }

    private func startWatching(url: URL, generation: UInt64) {
        lock.lock()
        let stillWatching = _watchedURL == url && _generation == generation
        lock.unlock()
        guard stillWatching else { return }
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File might not exist yet (atomic rename in progress), retry
            queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.startWatching(url: url, generation: generation)
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
            guard self._generation == generation, self._watchedURL == url else {
                self.lock.unlock()
                return
            }
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
                    self?.startWatching(url: url, generation: generation)
                }
            }
        }

        src.setCancelHandler {
            close(fd)
        }

        lock.lock()
        guard _generation == generation, _watchedURL == url else {
            lock.unlock()
            src.cancel()
            src.resume()
            return
        }
        _source = src
        _fileDescriptor = fd
        lock.unlock()

        src.resume()
    }
}

import Foundation

/// Watches a file for external modifications using kernel-level file system events.
@MainActor
public final class FileMonitorService {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.wardleymaps.filemonitor")

    public var onFileChanged: (@MainActor () -> Void)?

    public init() {}

    public func watch(url: URL) {
        stop()

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )

        let callback = onFileChanged
        source?.setEventHandler {
            Task { @MainActor in
                callback?()
            }
        }

        let fd = fileDescriptor
        source?.setCancelHandler {
            if fd >= 0 {
                close(fd)
            }
        }

        source?.resume()
    }

    public func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }
}

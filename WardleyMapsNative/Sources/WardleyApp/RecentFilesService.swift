import Foundation
import Observation

/// Persists a list of recently opened .owm file paths.
@Observable
public final class RecentFilesService {
    private static let key = "recentFiles"
    private static let maxCount = 10

    public var recentFiles: [URL]

    public init() {
        let bookmarks = UserDefaults.standard.array(forKey: Self.key) as? [Data] ?? []
        self.recentFiles = bookmarks.compactMap { data in
            var stale = false
            return try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                bookmarkDataIsStale: &stale
            )
        }
    }

    public func add(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > Self.maxCount {
            recentFiles = Array(recentFiles.prefix(Self.maxCount))
        }
        save()
    }

    public func clear() {
        recentFiles.removeAll()
        save()
    }

    private func save() {
        let bookmarks = recentFiles.compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope)
        }
        UserDefaults.standard.set(bookmarks, forKey: Self.key)
    }
}

import Foundation

/// File arguments for direct executable launches. Launch Services file-open
/// events are handled separately, including when the app is already running.
public enum MapFileArguments {
    public static func urls(from arguments: [String]) -> [URL] {
        var seen = Set<URL>()
        return arguments.compactMap { argument in
            guard !argument.hasPrefix("-") else { return nil }
            let url: URL
            if argument.hasPrefix("file://"), let fileURL = URL(string: argument) {
                url = fileURL
            } else {
                url = URL(fileURLWithPath: argument)
            }
            let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
            guard (try? canonical.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                  seen.insert(canonical).inserted else { return nil }
            return canonical
        }
    }
}

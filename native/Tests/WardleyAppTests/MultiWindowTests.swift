import Foundation
import Testing
@testable import WardleyApp

@Suite("Independent map sessions", .serialized)
@MainActor
struct MultiWindowTests {
    private func fixtureDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(25))
        }
        #expect(condition(), "Timed out waiting for the file monitor")
    }

    @Test("CLI opens all files, supports spaces and URLs, and deduplicates aliases")
    func arguments() throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = directory.appendingPathComponent("first map.owm")
        let second = directory.appendingPathComponent("second.wardley")
        let alias = directory.appendingPathComponent("alias.owm")
        try "title First".write(to: first, atomically: true, encoding: .utf8)
        try "title Second".write(to: second, atomically: true, encoding: .utf8)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: first)
        let urls = MapFileArguments.urls(from: [
            "-psn_123", first.path, second.absoluteString, alias.path,
            first.path, directory.path, directory.appendingPathComponent("missing.owm").path,
        ])
        #expect(urls == [first, second].map { $0.resolvingSymlinksInPath() })
    }

    @Test("Each map refreshes independently and stopping one preserves the other watcher")
    func independentWatchers() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstURL = directory.appendingPathComponent("first.owm")
        let secondURL = directory.appendingPathComponent("second.owm")
        try "title First".write(to: firstURL, atomically: true, encoding: .utf8)
        try "title Second".write(to: secondURL, atomically: true, encoding: .utf8)
        let first = MapEnvironmentState()
        let second = MapEnvironmentState()
        defer { first.stopMonitoring(); second.stopMonitoring() }
        first.openFile(firstURL)
        second.openFile(secondURL)

        try "title First updated".write(to: firstURL, atomically: true, encoding: .utf8)
        try await waitUntil { first.parsedMap.title == "First updated" }
        #expect(second.parsedMap.title == "Second")

        // Stop while the atomic-save watcher is waiting to reattach.
        first.stopMonitoring()
        try await Task.sleep(for: .milliseconds(200))
        try "title First stopped".write(to: firstURL, atomically: true, encoding: .utf8)
        try "title Second updated".write(to: secondURL, atomically: true, encoding: .utf8)
        try await waitUntil { second.parsedMap.title == "Second updated" }
        try await Task.sleep(for: .milliseconds(200))
        #expect(first.parsedMap.title == "First updated")
    }

    @Test("Saving and markers remain local to their map; failed saves stay dirty")
    func independentEdits() throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstURL = directory.appendingPathComponent("first.owm")
        let secondURL = directory.appendingPathComponent("second.owm")
        try "title First".write(to: firstURL, atomically: true, encoding: .utf8)
        try "title Second".write(to: secondURL, atomically: true, encoding: .utf8)
        let first = MapEnvironmentState()
        let second = MapEnvironmentState()
        let previousAutoSave = first.autoSaveEnabled
        first.autoSaveEnabled = false
        second.autoSaveEnabled = false
        defer {
            first.stopMonitoring(); second.stopMonitoring()
            first.hasUnsavedChanges = false
            first.autoSaveEnabled = previousAutoSave
        }
        first.openFile(firstURL)
        second.openFile(secondURL)
        first.mapText = "title First edited"
        first.hasUnsavedChanges = true
        first.marker.isActive = true
        #expect(first.saveToDisk())
        #expect(try String(contentsOf: secondURL, encoding: .utf8) == "title Second")
        #expect(second.parsedMap.title == "Second")
        #expect(!second.marker.isActive)
        #expect(!second.hasUnsavedChanges)

        first.stopMonitoring()
        first.fileURL = directory.appendingPathComponent("missing/subdir.owm")
        first.hasUnsavedChanges = true
        #expect(!first.saveToDisk())
        #expect(first.hasUnsavedChanges)
    }

    @Test("Stopping a window cancels its pending auto-save")
    func cancelledAutoSave() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("map.owm")
        try "title Original".write(to: url, atomically: true, encoding: .utf8)
        let state = MapEnvironmentState()
        let previousAutoSave = state.autoSaveEnabled
        defer {
            state.stopMonitoring()
            state.hasUnsavedChanges = false
            state.autoSaveEnabled = previousAutoSave
        }
        state.autoSaveEnabled = true
        state.openFile(url)
        state.mapText = "title Discarded"
        state.hasUnsavedChanges = true
        state.stopMonitoring()
        try await Task.sleep(for: .milliseconds(1200))
        #expect(try String(contentsOf: url, encoding: .utf8) == "title Original")
    }
}

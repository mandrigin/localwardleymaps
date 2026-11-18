import SwiftUI
import AppKit
import WardleyApp

@main
struct WardleyMapsNativeApp: App {
    @NSApplicationDelegateAdaptor(WardleyApplicationDelegate.self) private var delegate

    var body: some Scene {
        // AppKit owns document windows so Finder and `open -a` requests use the
        // same routing on first launch and while the application is running.
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {}
                MapWindowCommands(windows: delegate.windows)
            }
    }
}

@MainActor
final class WardleyApplicationDelegate: NSObject, NSApplicationDelegate {
    let windows = MapWindowManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        windows.openFiles(MapFileArguments.urls(from: Array(CommandLine.arguments.dropFirst())))
        if windows.controllers.isEmpty {
            windows.newWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        windows.openFiles(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { windows.newWindow() }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        windows.controllers.allSatisfy { $0.confirmClose() } ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        for controller in windows.controllers { controller.state.stopMonitoring() }
    }
}

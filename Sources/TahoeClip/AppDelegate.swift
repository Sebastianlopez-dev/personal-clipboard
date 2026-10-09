import AppKit
import ClipCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var watcher: ClipboardWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = InMemoryClipboardStore()
        statusItemController = StatusItemController()
        watcher = ClipboardWatcher(store: store, privacyFilter: PrivacyFilter())
        watcher?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher?.stop()
    }
}

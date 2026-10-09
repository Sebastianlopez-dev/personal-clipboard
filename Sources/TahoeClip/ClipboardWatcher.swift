import AppKit
import ClipCore

// Timer access stays on its installing thread, including off-actor destruction.
// This sendable lifetime handle exposes only main-thread-dispatched invalidation.
private final class TimerLifetime: @unchecked Sendable {
    private let timer: Timer
    @MainActor init(_ timer: Timer) { self.timer = timer }
    func invalidate() {
        if Thread.isMainThread {
            timer.invalidate()
        } else {
            DispatchQueue.main.async { [self] in timer.invalidate() }
        }
    }
}

@MainActor
final class ClipboardWatcher {
    enum CaptureError: Equatable {
        case readFailed
        case storeFailed

        var message: String {
            switch self {
            case .readFailed: "Clipboard text capture failed."
            case .storeFailed: "Clipboard item storage failed."
            }
        }
    }

    private struct Capture {
        let sourceBundleID: String?
        var item: ClipboardItem?
        var attempts = 0
    }

    private let store: ClipboardStore
    private let privacyFilter: PrivacyFilter
    private let changeCount: () -> Int
    private let readText: () throws -> String?
    private let sourceBundleID: () -> String?
    private let schedule: (@escaping @MainActor () -> Void) -> Timer
    private let reportError: (CaptureError) -> Void
    private var timer: TimerLifetime?
    private var generation = UUID()
    private var lastChangeCount: Int
    private var pending: Capture?

    convenience init(
        pasteboard: NSPasteboard = .general,
        store: ClipboardStore,
        privacyFilter: PrivacyFilter
    ) {
        self.init(
            store: store, privacyFilter: privacyFilter,
            changeCount: { pasteboard.changeCount },
            readText: { pasteboard.string(forType: .string) },
            sourceBundleID: { NSWorkspace.shared.frontmostApplication?.bundleIdentifier },
            schedule: { tick in
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in tick() }
                }
            },
            reportError: { NSLog("%@", $0.message) }
        )
    }

    // Internal seams keep tests independent of the system clipboard and wall clock.
    init(
        store: ClipboardStore,
        privacyFilter: PrivacyFilter,
        changeCount: @escaping () -> Int,
        readText: @escaping () throws -> String?,
        sourceBundleID: @escaping () -> String?,
        schedule: @escaping (@escaping @MainActor () -> Void) -> Timer,
        reportError: @escaping (CaptureError) -> Void
    ) {
        self.store = store
        self.privacyFilter = privacyFilter
        self.changeCount = changeCount
        self.readText = readText
        self.sourceBundleID = sourceBundleID
        self.schedule = schedule
        self.reportError = reportError
        self.lastChangeCount = changeCount()
    }

    deinit { timer?.invalidate() }

    func start() {
        guard timer == nil else { return }
        generation = UUID()
        let currentGeneration = generation
        timer = TimerLifetime(schedule { [weak self] in
            guard let self, self.timer != nil,
                  self.generation == currentGeneration else { return }
            self.poll()
        })
    }

    func stop() {
        generation = UUID()
        timer?.invalidate()
        timer = nil
        pending = nil
    }

    private func poll() {
        let count = changeCount()
        if count != lastChangeCount {
            lastChangeCount = count
            // Detection-time approximation, sampled once even when capture retries.
            pending = Capture(sourceBundleID: sourceBundleID())
        }
        guard var capture = pending else { return }
        capture.attempts += 1
        if capture.item == nil {
            do {
                guard let text = try readText() else {
                    pending = nil // No supported text: terminal, not a read failure.
                    return
                }
                guard changeCount() == count else {
                    pending = nil // Do not store text from a superseding clipboard change.
                    return
                }
                guard privacyFilter.shouldCapture(text: text, sourceAppBundleID: capture.sourceBundleID) else {
                    pending = nil // Filtered content is terminal and NEVER retried.
                    return
                }
                capture.item = ClipboardItem(content: text, sourceAppBundleID: capture.sourceBundleID)
            } catch {
                failed(.readFailed, capture: capture)
                return
            }
        }
        guard let item = capture.item else { return }
        do {
            try store.insert(item)
            pending = nil
        } catch {
            failed(.storeFailed, capture: capture)
        }
    }

    private func failed(_ error: CaptureError, capture: Capture) {
        // Three total attempts per change (initial + two retries), one per poll.
        // A newer change or stop discards the pending capture; errors expose no content.
        pending = capture.attempts < 3 ? capture : nil
        reportError(error)
    }
}

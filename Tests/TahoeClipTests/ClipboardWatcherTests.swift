import Foundation
import Testing
import ClipCore
@testable import TahoeClip

private struct SensitiveFailure: Error { let detail = "password=never-log-this" }

private final class FailingStore: ClipboardStore {
    var attempts: [ClipboardItem] = []
    var failures = 0
    func insert(_ item: ClipboardItem) throws {
        attempts.append(item)
        if failures > 0 { failures -= 1; throw SensitiveFailure() }
    }
    func recent(limit: Int) throws -> [ClipboardItem] { [] }
    func clear() throws {}
}

@MainActor private final class Fixture {
    var count = 0
    var text: String? = "ordinary text"
    var source = "original.source"
    var sourceReads = 0
    var textReads = 0
    var readFailures = 0
    var errors: [ClipboardWatcher.CaptureError] = []
    var timers: [Timer] = []
    var ticks: [@MainActor () -> Void] = []
    let store = FailingStore()

    func watcher(filter: PrivacyFilter = PrivacyFilter()) -> ClipboardWatcher {
        ClipboardWatcher(
            store: store, privacyFilter: filter,
            changeCount: { self.count },
            readText: {
                self.textReads += 1
                if self.readFailures > 0 { self.readFailures -= 1; throw SensitiveFailure() }
                return self.text
            },
            sourceBundleID: { self.sourceReads += 1; return self.source },
            schedule: { tick in
                self.ticks.append(tick)
                let timer = Timer(timeInterval: 100, repeats: true) { _ in }
                self.timers.append(timer)
                return timer
            },
            reportError: { self.errors.append($0) }
        )
    }
}

@Test @MainActor func duplicateStartStopAndStaleTicks() {
    let f = Fixture()
    let watcher = f.watcher()
    watcher.start(); watcher.start()
    #expect(f.timers.count == 1)
    watcher.stop(); watcher.stop()
    #expect(!f.timers[0].isValid)
    f.count = 1
    f.ticks[0]()
    #expect(f.textReads == 0)
    watcher.start()
    #expect(f.timers.count == 2)
    f.ticks[0]()
    #expect(f.textReads == 0)
    f.ticks[1]()
    #expect(f.store.attempts.count == 1)
    watcher.stop()
}

@Test @MainActor func releaseInvalidatesTimer() {
    let f = Fixture()
    var watcher: ClipboardWatcher? = f.watcher()
    watcher?.start()
    watcher = nil
    #expect(!f.timers[0].isValid)
}

@Test @MainActor func retriesReuseItemAndApproximateSource() {
    let f = Fixture()
    f.store.failures = 2
    let watcher = f.watcher()
    watcher.start(); f.count = 1
    f.ticks[0]()
    f.source = "later.source"; f.text = "changed without count"
    f.ticks[0](); f.ticks[0](); f.ticks[0]()
    #expect(f.sourceReads == 1)
    #expect(f.textReads == 1)
    #expect(f.store.attempts.count == 3)
    #expect(Set(f.store.attempts.map(\.id)).count == 1)
    #expect(f.store.attempts.allSatisfy { $0.sourceAppBundleID == "original.source" })
    #expect(f.errors == [.storeFailed, .storeFailed])
    watcher.stop()
}

@Test @MainActor func readFailuresAreBoundedAndContentFree() {
    let f = Fixture()
    f.readFailures = 10
    let watcher = f.watcher()
    watcher.start(); f.count = 1
    for _ in 0..<8 { f.ticks[0]() }
    #expect(f.textReads == 3)
    #expect(f.sourceReads == 1)
    #expect(f.errors == [.readFailed, .readFailed, .readFailed])
    #expect(f.errors.allSatisfy { !$0.message.contains("password") })
    #expect(f.store.attempts.isEmpty)
    watcher.stop()
}

@Test @MainActor func filteredItemsNeverRetry() {
    let f = Fixture()
    f.text = "password=filtered"
    let watcher = f.watcher()
    watcher.start(); f.count = 1
    for _ in 0..<5 { f.ticks[0]() }
    #expect(f.textReads == 1)
    #expect(f.store.attempts.isEmpty)
    #expect(f.errors.isEmpty)
    watcher.stop()
}

@Test @MainActor func newChangeSupersedesFailedCaptureAndStopDiscardsRetry() {
    let f = Fixture()
    f.store.failures = 10
    let watcher = f.watcher()
    watcher.start(); f.count = 1; f.ticks[0]()
    f.count = 2; f.source = "new.source"; f.text = "new text"
    f.ticks[0]()
    #expect(f.sourceReads == 2)
    #expect(f.store.attempts.last?.content == "new text")
    watcher.stop(); watcher.start(); f.ticks[1]()
    #expect(f.store.attempts.count == 2)
    watcher.stop()
}

@Test @MainActor func ignoredDetectionSourceRemainsFilteredAfterFocusChanges() {
    let f = Fixture()
    let watcher = f.watcher(filter: PrivacyFilter(ignoredBundleIDs: ["original.source"]))
    watcher.start(); f.count = 1; f.ticks[0]()
    f.source = "allowed.source"
    for _ in 0..<5 { f.ticks[0]() }
    #expect(f.sourceReads == 1)
    #expect(f.textReads == 1)
    #expect(f.store.attempts.isEmpty)
    watcher.stop()
}

@Test @MainActor func readRetryReusesDetectionSource() {
    let f = Fixture()
    f.readFailures = 1
    let watcher = f.watcher()
    watcher.start(); f.count = 1; f.ticks[0]()
    f.source = "later.source"
    f.ticks[0](); f.ticks[0]()
    #expect(f.textReads == 2)
    #expect(f.sourceReads == 1)
    #expect(f.store.attempts.count == 1)
    #expect(f.store.attempts.first?.sourceAppBundleID == "original.source")
    #expect(f.errors == [.readFailed])
    watcher.stop()
}

@Test @MainActor func storageFailuresStopAfterThreeAttempts() {
    let f = Fixture()
    f.store.failures = 10
    let watcher = f.watcher()
    watcher.start(); f.count = 1
    for _ in 0..<8 { f.ticks[0]() }
    #expect(f.store.attempts.count == 3)
    #expect(f.textReads == 1)
    #expect(f.errors == [.storeFailed, .storeFailed, .storeFailed])
    #expect(f.errors.allSatisfy { !$0.message.contains("password") })
    watcher.stop()
}

@Test @MainActor func unsupportedTextIsTerminalWithoutAnError() {
    let f = Fixture()
    f.text = nil
    let watcher = f.watcher()
    watcher.start(); f.count = 1
    for _ in 0..<5 { f.ticks[0]() }
    #expect(f.textReads == 1)
    #expect(f.store.attempts.isEmpty)
    #expect(f.errors.isEmpty)
    watcher.stop()
}

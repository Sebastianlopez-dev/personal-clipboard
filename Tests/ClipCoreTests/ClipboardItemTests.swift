import Foundation
import Testing
@testable import ClipCore

@Test func textConstructionDerivesIdentity() {
    let item = ClipboardItem(content: "abc", sourceAppBundleID: "example.source")
    #expect(item.kind == "text")
    #expect(item.preview == "abc")
    #expect(item.contentHash == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    #expect(item.sourceAppBundleID == "example.source")
}

@Test func previewPreservesUnicodeAndBoundsLength() {
    let text = String(repeating: "👨‍👩‍👧‍👦", count: 121)
    let item = ClipboardItem(content: text)
    #expect(item.preview == String(text.prefix(120)))
    #expect(item.content == text)
    #expect(item.contentHash == ClipboardItem(content: text).contentHash)
    #expect(item.contentHash != ClipboardItem(content: text + "!").contentHash)
}

@Test func storeDeduplicatesAndMovesNewestCaptureToFront() throws {
    let store = InMemoryClipboardStore()
    let first = ClipboardItem(content: "same", sourceAppBundleID: "first")
    let newest = ClipboardItem(content: "same", sourceAppBundleID: "newest")
    try store.insert(first)
    try store.insert(ClipboardItem(content: "different"))
    try store.insert(newest)
    let items = try store.recent(limit: 10)
    #expect(items.count == 2)
    #expect(items.first == newest)
    #expect(try store.recent(limit: -1).isEmpty)
    try store.clear()
    #expect(try store.recent(limit: 10).isEmpty)
}

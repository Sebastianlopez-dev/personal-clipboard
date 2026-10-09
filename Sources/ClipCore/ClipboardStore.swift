import Foundation

public protocol ClipboardStore {
    func recent(limit: Int) throws -> [ClipboardItem]
    func insert(_ item: ClipboardItem) throws
    func clear() throws
}

public final class InMemoryClipboardStore: ClipboardStore {
    private var items: [ClipboardItem] = []

    public init() {}

    public func recent(limit: Int) throws -> [ClipboardItem] {
        Array(items.prefix(max(0, limit)))
    }

    public func insert(_ item: ClipboardItem) throws {
        items.removeAll { $0.contentHash == item.contentHash }
        items.insert(item, at: 0)
    }

    public func clear() throws {
        items.removeAll()
    }
}

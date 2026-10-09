import Foundation
import CryptoKit

public struct ClipboardItem: Equatable, Sendable {
    public let id: UUID
    public var kind: String { "text" }
    public let preview: String
    public let content: String
    public let contentHash: String
    /// Approximate frontmost application at detection, not a verified clipboard owner.
    public let sourceAppBundleID: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        content: String,
        sourceAppBundleID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.preview = String(content.prefix(120))
        self.content = content
        self.contentHash = SHA256.hash(data: Data(content.utf8))
            .map { String(format: "%02x", $0) }.joined()
        self.sourceAppBundleID = sourceAppBundleID
        self.createdAt = createdAt
    }
}

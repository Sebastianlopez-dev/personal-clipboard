import Foundation

public struct SQLiteDatabase: Sendable {
    public enum Error: LocalizedError, Equatable, Sendable {
        case notImplemented

        public var errorDescription: String? {
            "SQLite migrations are not implemented in this scaffold."
        }
    }

    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func migrate() throws {
        throw Error.notImplemented
    }
}

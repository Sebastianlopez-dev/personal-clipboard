import Foundation
import Testing
@testable import ClipCore

@Test func migrateFailsExplicitlyUntilImplemented() {
    let database = SQLiteDatabase(url: URL(fileURLWithPath: "/unused/clipboard.sqlite"))
    var migrationError: (any Error)?

    do {
        try database.migrate()
    } catch {
        migrationError = error
    }

    #expect(migrationError != nil)
    #expect(migrationError as? SQLiteDatabase.Error == .notImplemented)
}

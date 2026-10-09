import Foundation

public enum AppPaths {
    public static func applicationSupportDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("TahoeClip", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public static func databaseURL() throws -> URL {
        try applicationSupportDirectory().appendingPathComponent("history.sqlite")
    }
}

import Foundation

public struct PrivacyFilter: Sendable {
    public var maximumTextLength: Int
    public var ignoredBundleIDs: Set<String>

    public init(maximumTextLength: Int = 20_000, ignoredBundleIDs: Set<String> = []) {
        self.maximumTextLength = maximumTextLength
        self.ignoredBundleIDs = ignoredBundleIDs
    }

    public func shouldCapture(text: String, sourceAppBundleID: String?) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard text.count <= maximumTextLength else { return false }

        if let sourceAppBundleID, ignoredBundleIDs.contains(sourceAppBundleID) {
            return false
        }

        return !looksLikeSecret(trimmed)
    }

    private func looksLikeSecret(_ text: String) -> Bool {
        let lowered = text.lowercased()
        if lowered.contains("-----begin private key-----") { return true }
        if lowered.contains("password=") || lowered.contains("passwd=") { return true }
        if text.count >= 80 && text.range(of: #"^[A-Za-z0-9_\-\.]{80,}$"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }
}

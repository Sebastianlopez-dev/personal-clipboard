import Testing
@testable import ClipCore

@Test func rejectsEmptyText() {
    let filter = PrivacyFilter()
    #expect(filter.shouldCapture(text: "   ", sourceAppBundleID: nil) == false)
}

@Test func rejectsPrivateKeys() {
    let filter = PrivacyFilter()
    #expect(filter.shouldCapture(text: "-----BEGIN PRIVATE KEY-----\nabc", sourceAppBundleID: nil) == false)
}

@Test func acceptsNormalText() {
    let filter = PrivacyFilter()
    #expect(filter.shouldCapture(text: "Remember this", sourceAppBundleID: nil) == true)
}

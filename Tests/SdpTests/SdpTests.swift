import XCTest
@testable import Sdp

final class SdpTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Sdp().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

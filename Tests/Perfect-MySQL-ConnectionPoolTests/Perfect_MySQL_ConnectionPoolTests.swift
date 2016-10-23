import XCTest
@testable import Perfect_MySQL_ConnectionPool

class Perfect_MySQL_ConnectionPoolTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Perfect_MySQL_ConnectionPool().text, "Hello, World!")
    }


    static var allTests : [(String, (Perfect_MySQL_ConnectionPoolTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

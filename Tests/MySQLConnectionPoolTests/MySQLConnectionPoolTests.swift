import XCTest
@testable import MySQLConnectionPool



let testHost = "127.0.0.1"
let testUser = "root"
let testPort = 3306
// PLEASE change to whatever your actual password is before running these tests
let testPassword = ""//testpassword"
let testScheme = "test"



class MySQLConnectionPoolTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        //  connect and select DB
    }
    
    override func tearDown() {
        super.tearDown()
        
    }
    
    func getConn() -> Connection{
        return Connection(lastConnectionId, host: testHost, port: testPort, user: testUser, pass: testPassword, scheme: testScheme)
    }
    
    
}

import XCTest
@testable import MySQLConnectionPool



let testHost = "127.0.0.1"
let testUser = "root"
let testPort = 3306
// PLEASE change to whatever your actual password is before running these tests
let testPassword = ""//testpassword"
let testScheme = "test"



class MySQLConnectionPoolTests: XCTestCase {
    var lastConnectionId: Int = 0
    override func setUp() {
        super.setUp()
        
        //  connect and select DB
    }
    
    override func tearDown() {
        super.tearDown()
        
    }
    
    func getConn() -> Connection{
        lastConnectionId += 1
        return Connection(lastConnectionId, host: testHost, port: testPort, user: testUser, pass: testPassword, scheme: testScheme)
    }
    
    func test_connection() {
        let con = getConn()
        if con.lastError.errorCode != 0 {
            XCTFail("Cannot connect to MySQL: " + con.lastError.errorMessage)
        } else {
            con.close()
        }
    }

    func test_error_connection() {
        lastConnectionId += 1
        let con = Connection(lastConnectionId, host: testHost, port: testPort, user: testUser, pass: "errorPass3234", scheme: testScheme)

        if con.lastError.errorCode != 1045 {
            XCTFail("Cannot get error 1045, I got \(con.lastError.errorCode): " + con.lastError.errorMessage)
        } else {
            con.close()
        }
    }
    
}

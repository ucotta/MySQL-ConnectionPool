import XCTest
@testable import MySQLConnectionPool



let testHost = "127.0.0.1"
let testUser = "root"
let testPort = 3306
// PLEASE change to whatever your actual password is before running these tests
let testPassword = ""//testpassword"


let QUERY_CREATE_TABLE = "CREATE TABLE `tableTest` ( " +
		"`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, " +
		"`title` VARCHAR(255) NOT NULL DEFAULT '', " +
		"`subject` text NOT NULL, " +
		"`amount` double DEFAULT NULL, " +
		"`chargeDate` datetime NOT NULL," +
	"PRIMARY KEY (`id`) " +
	") ENGINE=MyISAM DEFAULT CHARSET=utf8;"


var tests = [String]()

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
		let con = Connection(lastConnectionId, host: testHost, port: testPort, user: testUser, pass: testPassword, scheme: nil)
		if con.lastError.errorCode != 0 {
			XCTFail("Cannot connect to MySQL: " + con.lastError.errorMessage)
		}
		_ = con.mysql.selectDatabase(named: "test")
		return con
	}

	func test_error_connection() {
		lastConnectionId += 1
		let con = Connection(lastConnectionId, host: testHost, port: testPort, user: testUser, pass: "errorPass3234", scheme: nil)

		if con.lastError.errorCode != 1045 {
			XCTFail("Cannot get error 1045, I got \(con.lastError.errorCode): " + con.lastError.errorMessage)
		} else {
			con.close()
		}
	}

	func test_prepareDB() {
		tests.append("test_prepareDB")
		let con = getConn()
		defer { con.close() }
		guard con.mysql.query(statement: "DROP DATABASE IF EXISTS test") && con.mysql.query(statement: "CREATE DATABASE test CHARACTER SET utf8") else {
			XCTFail("Cannot create database: " + con.mysql.errorMessage())
			return
		}

		guard con.mysql.selectDatabase(named: "test") else {
			XCTFail("Cannot select table: " + con.mysql.errorMessage())
			return
		}

		guard con.mysql.query(statement: QUERY_CREATE_TABLE) else {
			XCTFail("Cannot create table: " + con.mysql.errorMessage())
			return
		}
	}

	func test_insert() throws {
		if !tests.contains("test_prepareDB") {
			test_prepareDB()
		}
		tests.append("test_insert")
		let con = getConn()
		defer { con.close() }

		var data: [(String, String)] = []
		data.append(("title", "Title 1"))
		data.append(("subject", "this is a very long text"))
		data.append(("amount", "234.24"))
		data.append(("chargeDate", "2000-01-01"))

		do {
			let id = try con.insert(table: "tableTest", fields: "title,subject,amount,chargeDate", args: data)
			XCTAssertGreaterThanOrEqual(id, 1, "error in insert")
		} catch let error {
			XCTFail(error.localizedDescription)
		}

	}

	func test_count() throws {
		if !tests.contains("test_insert") {
			try test_insert()
		}
		tests.append("test_count")

		let con = getConn()
		defer { con.close() }
		let a = try con.getCount(sql: "SELECT count(*) FROM tableTest")
		XCTAssertGreaterThan(a, 0, "error getcount")
	}

	func test_update() throws {
		if !tests.contains("test_insert") {
			try test_insert()
		}
		let con = getConn()
		defer { con.close() }

		var data: [(String, String)] = []
		data.append(("title", "Title 2"))
		data.append(("subject", "this is a very long text now more large!"))
		data.append(("amount", "274.24"))
		data.append(("chargeDate", "2010-01-01"))

		do {
			try con.update(table: "tableTest", id: 1, fields: "title,subject,amount,chargeDate", args: data)
		} catch let error {
			XCTFail(error.localizedDescription)
		}
		
	}
}

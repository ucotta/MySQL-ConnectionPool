//
//  Connection.swift
//  Paella
//
//  Created by Ubaldo Cotta on 24/10/16.
//
//

import Foundation
import MySQL

public class Connection: Equatable {
	private var lastError = (0, "")
	public let mysql:MySQL
	private let idConnection:Int

	public init(_ idConnection:Int = -1, host:String, port:Int, user:String, pass:String, scheme:String?) {
		self.idConnection = idConnection
		mysql = MySQL()

		guard mysql.connect(host: host, user: user, password: pass, port: UInt32(port)) else {
			lastError = (Int(mysql.errorCode()), "Can not connect  \(mysql.errorCode()) \(mysql.errorMessage())")
			return
		}

		if let db = scheme {
			// Test connection selecting the database.
			guard mysql.selectDatabase(named: db) else {
				lastError = (Int(mysql.errorCode()), "Can not select database  \(mysql.errorCode()) \(mysql.errorMessage())")
				return
			}
		}
		//print("INIT")
	}

	public func close() {
		mysql.close()
	}

	public func returnToPool() {
		//print("return to pool")
		ConnectionPool.sharedInstance.returnConnection(conn: self)
	}

	deinit {
		//print("DEINIT")
		mysql.close()
		//ConnectionPool.sharedInstance.removeConnection(conn: self)
	}


	public static func ==(left: Connection, right: Connection) -> Bool {
		return left.idConnection == right.idConnection
	}

	public func getLastError() -> (errorCode:Int, errorMessage:String) {
		return lastError
	}

	private func addParams(_ stmt: MySQLStmt, args:[Any]) throws {
		var i = 0
		for item in args {
			switch item {
			case let val as Int:
				stmt.bindParam(val)
			case let val as UInt64:
				stmt.bindParam(val)
			case let val as Double:
				stmt.bindParam(val)
			case let val as String:
				stmt.bindParam(val)
			case let val as Date:
				// Dateformatter use localtime.
				let formatter = DateFormatter()
				formatter.dateFormat = "YYY-MM-dd hh:mm:ss"
				stmt.bindParam(formatter.string(from: val))
				//case let val as Time:
				//    stmt.bindParam(fromTime: val)
				//case let val as DateTime:
			//    stmt.bindParam(fromDate:val)
			default:
				throw ConnectionError.fieldTypeNotSupported(fieldRow: i, fieldData: item)
			}
			i += 1
		}

	}

	private func resetError() {
		lastError = (0, "")
	}

	public func queryRow(_ query: String) throws -> Array<Optional<Any>>? {
		resetError()

		if mysql.query(statement: query) {
			if let results = mysql.storeResults() {
				//setup an array to store results
				defer { results.close() }
				if let row = results.next() {
					return row
				}
			}
		} else {
			lastError = (Int(mysql.errorCode()), "Cannot create query  \(mysql.errorCode()) \(mysql.errorMessage())")
			throw ConnectionError.errorPrepareQuery(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		return nil
	}

	public func queryRow(_ query: String, args: Any...) throws -> [Any?]? {
		resetError()

		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement  \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			lastError = (Int(stmt.errorCode()), "Cannot execute statement  \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		var result:[Any?] = []

		_ = datos.forEachRow { row in
			// return just the first record.
			if result.isEmpty {
				result = row
			}
		}

		return result.isEmpty ? nil : result
	}

	public func queryAll(_ query:String, closure: (_ row:  Array<Optional<Any>>)->()) throws {
		resetError()

		if mysql.query(statement: query) {
			if let results = mysql.storeResults() {
				//setup an array to store results
				defer { results.close() }
				while let row = results.next() {
					closure(row)
				}
			}
		} else {
			lastError = (Int(mysql.errorCode()), "Cannot create query  \(mysql.errorCode()) \(mysql.errorMessage())")
			throw ConnectionError.errorPrepareQuery(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

	}

	public func queryAll(_ query:String, args:Any..., closure: (_ row:  Array<Optional<Any>>)->()) throws {
		resetError()

		//print("queryAll \(self.idConnection)")

		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		_ = datos.forEachRow { row in

			closure(row)
		}
		//print("queryAll end \(self.idConnection)")

	}

	public func execute(_ query:String) throws {
		if !mysql.query(statement: query) {
			lastError = (Int(mysql.errorCode()), "Cannot create query  \(mysql.errorCode()) \(mysql.errorMessage())")
			throw ConnectionError.errorPrepareQuery(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		// Free any result other wise it failt with error 2014 : Commands out of sync
		if let results = mysql.storeResults() {
			results.close()
		}
	}

	public func execute(_ query:String, args:Any...) throws {
		resetError()

		
		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		// Free any result other wise it failt with error 2014 : Commands out of sync
		if let results = mysql.storeResults() {
			results.close()
		}
	}


}


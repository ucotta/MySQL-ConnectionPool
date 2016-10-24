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
		print("INIT")
	}

	public func close() {
		mysql.close()
	}

	deinit {
		print("DEINIT")
		mysql.close()
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
			print("\(i) = \(item)")
			i += 1
			switch item {
			case let val as Int:
				stmt.bindParam(val)
			case let val as UInt64:
				stmt.bindParam(val)
			case let val as Double:
				stmt.bindParam(val)
			case let val as String:
				stmt.bindParam(val)
				//case let val as Date:
				//	stmt.bindParam(fromDateTime: val)
				//case let val as Time:
				//    stmt.bindParam(fromTime: val)
				//case let val as DateTime:
			//    stmt.bindParam(fromDate:val)
			default:
				throw MySQLError.notSupportedType(parameter: item)
			}
		}

	}

	private func resetError() {
		lastError = (0, "")
	}

	public func queryRow(_ query:String, args:Any...) throws -> Array<Optional<Any>>? {
		resetError()

		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement  \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			lastError = (Int(stmt.errorCode()), "Cannot execute statement  \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
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

		return result
	}

	public func queryAll(query:String, args:Any..., closure: (_ row:  Array<Optional<Any>>)->()) throws {
		resetError()

		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		_ = datos.forEachRow { row in

			closure(row)
		}
	}

}


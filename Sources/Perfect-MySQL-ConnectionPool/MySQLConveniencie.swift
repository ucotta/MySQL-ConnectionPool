//
//  MySQLConveniencie.swift
//
//  Created by Ubaldo Cotta on 24/10/16.
//
//  Some clases to easy use of mysql
//

//import MySQL
import PerfectLib
import Foundation
import MySQL


enum MySQLError: Error {
	case inSelectDatabase(errorCode: Int, errorMessage: String)
	case errorConnecting(errorCode: Int, errorMessage: String)
	case errorPrepareStatement(errorCode: Int, errorMessage: String)
	case errorExecute(errorCode: Int, errorMessage: String)
	case notSupportedType(parameter: Any)

}

public class MySQLHelper {
	private let host:String
	private let user:String
	private let pass:String
	private let scheme:String
	private let db:String

	public init(host:String, user:String, pass:String, scheme:String, db:String) {
		self.host = host
		self.user = user
		self.pass = pass
		self.scheme = scheme
		self.db = db
	}

	public func checkConnection() throws -> Bool {
		let mysql = MySQL()

		guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
			Log.critical(message: "There was not possible to connect to MySQL: " + mysql.errorMessage())
			throw MySQLError.errorConnecting(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		defer { mysql.close() }

		// Test connection selecting the database.
		guard mysql.selectDatabase(named: scheme) else {
			Log.critical(message: "There was an error connecting to the database: \(mysql.errorCode()) \(mysql.errorMessage())")
			throw MySQLError.inSelectDatabase(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		return true
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


	public func queryRow(_ query:String, args:Any...) throws -> Array<Optional<Any>>? {
		let mysql = MySQL()
		var result:Array<Optional<Any>>?

		guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
			Log.critical(message: "There was not possible to connect to MySQL: " + mysql.errorMessage())
			throw MySQLError.errorConnecting(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		defer { mysql.close() }


		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			Log.error(message: "Cannot create statement in SessionMySQL.dbGetCookieData: \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		_ = datos.forEachRow { row in
			result = row
			return
		}

		return result
	}

	public func queryAll(query:String, args:Any..., closure: (_ row:  Array<Optional<Any>>)->()) throws {
		let mysql = MySQL()
		var result:Array<Array<Optional<Any>>> = []


		guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
			Log.critical(message: "There was not possible to connect to MySQL: " + mysql.errorMessage())
			throw MySQLError.errorConnecting(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		defer { mysql.close() }


		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			Log.error(message: "Cannot create statement in SessionMySQL.dbGetCookieData: \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		_ = datos.forEachRow { row in
			//var data:Array<Optional<Any>> = []
			//for item in row {
			//	data.append(item)
			//}
			//result.append(data)
			closure(row)
		}
	}
	/*
	public func queryAll(_ query:String, args:Any...) throws -> Array<Array<Optional<Any>>>? {
	let mysql = MySQL()
	var result:Array<Array<Optional<Any>>> = []


	guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
	Log.critical(message: "There was not possible to connect to MySQL: " + mysql.errorMessage())
	throw MySQLError.errorConnecting(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
	}
	defer { mysql.close() }


	let stmt:MySQLStmt = MySQLStmt(mysql)
	defer { stmt.close() }

	guard stmt.prepare(statement: query) else {
	Log.error(message: "Cannot create statement in SessionMySQL.dbGetCookieData: \(stmt.errorCode()) \(stmt.errorMessage())")
	throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
	}

	try addParams(stmt, args: args)

	if !stmt.execute() {
	throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
	}
	let datos = stmt.results()
	defer { stmt.freeResult() }

	_ = datos.forEachRow { row in
	var data:Array<Optional<Any>> = []
	for item in row {
	data.append(item)
	}
	result.append(data)
	}

	return result
	}
	*/


	public func execute(_ query:String, args:Any...) throws {
		let mysql = MySQL()
		var result:Array<Optional<Any>>?

		guard mysql.connect(host: host, user: user, password: pass, db: scheme) else {
			Log.critical(message: "There was not possible to connect to MySQL: " + mysql.errorMessage())
			throw MySQLError.errorConnecting(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		defer { mysql.close() }


		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			Log.error(message: "Cannot create statement in SessionMySQL.dbGetCookieData: \(stmt.errorCode()) \(stmt.errorMessage())")
			throw MySQLError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

		if !stmt.execute() {
			throw MySQLError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
	}
	
	
}

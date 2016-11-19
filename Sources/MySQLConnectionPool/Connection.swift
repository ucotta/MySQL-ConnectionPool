//
//  Connection.swift
//  Paella
//
//  Created by Ubaldo Cotta on 24/10/16.
//
//

import Foundation
import MySQL

private class PreparedStatementResult {
	let stmt: MySQLStmt
	let fields: [String]
	let results: MySQLStmt.Results
	
	init(stmt: MySQLStmt, fields: [String]) {
		self.stmt = stmt
		self.fields = fields
		self.results = stmt.results()
	}
	
	deinit {
		stmt.freeResult()
		stmt.close()
	}
}

public class Connection: Equatable {
	private var _lastError = (0, "")
	public let mysql:MySQL
	public let idConnection:Int

	public init(_ idConnection:Int = -1, host:String, port:Int, user:String, pass:String, scheme:String?) {
		self.idConnection = idConnection
		mysql = MySQL()
        _ = mysql.setOption(.MYSQL_SET_CHARSET_NAME, "utf8")

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
	}

	public func close() {
		mysql.close()
	}

	public func returnToPool() {
		//print("return to pool \(idConnection)")
		MySQLConnectionPool.sharedInstance.returnConnection(conn: self)
	}

	deinit {
		//print("DEINIT connection \(idConnection)")
		mysql.close()
	}


	public static func ==(left: Connection, right: Connection) -> Bool {
		return left.idConnection == right.idConnection
	}

    public var lastError: (errorCode:Int, errorMessage:String) {
        get {
            return self._lastError
        }
        set {
            _lastError = newValue
        }
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
				formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
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
	
	private func prepareStatement(_ query:String, args: [Any?]?) throws -> PreparedStatementResult {
		lastError = (0, "")
		
		let stmt:MySQLStmt = MySQLStmt(mysql)
		
		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		if let parameters = args {
			try addParams(stmt, args: parameters)
		}
		
		var keys = [String]()
		for index in 0..<Int(stmt.fieldCount()) {
			let fieldInfo = stmt.fieldInfo(index: index)
			keys.append(fieldInfo?.name ?? "?")
		}
		
		if !stmt.execute() {
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		return PreparedStatementResult(stmt: stmt, fields: keys)
	}

    /*
	public func queryRow(_ query: String) throws -> [String: Any?]? {
		guard mysql.query(statement: query) else {
			return nil

		}

		//store complete result set
		let storeResults = dataMysql.storeResults()
		var result:[String: Any?] = [:]

		if let row = storeResults?.next() {
			for (key, value) in zip(stmt.fields, row) {
				result[key] = correctData(data: value)
			}
			return result
		}

		return nil
	}
	*/

	private func correctData(data: Any?) -> Any? {
        guard data != nil else {
            return data
        }
		if data! is [UInt8] {
			return String(bytes: data as! [UInt8], encoding: String.Encoding.utf8)
		}
		return data
	}


	public func queryRow(_ query: String, args: Any...) throws -> [String: Any?]? {
		let stmt = try prepareStatement(query, args: args)
		
		var result:[String: Any?] = [:]
		
		_ = stmt.results.forEachRow { row in
			// return just the first record.
			if result.isEmpty {
				for (key, value) in zip(stmt.fields, row) {
					result[key] = correctData(data: value)
				}
			}
		}
		return result.isEmpty ? nil : result
	}
	

	public func queryAll(_ query:String) throws -> [[String: Any?]] {
		let stmt = try prepareStatement(query, args: nil)
		
		var result:[[String: Any?]] = []
		
		_ = stmt.results.forEachRow { row in
			var dic = [String: Any?]()
			for (key, value) in zip(stmt.fields, row) {
				dic[key] = correctData(data: value)
			}
			result.append(dic)
		}
		return result
	}
	
	public func queryAll(_ query:String, closure: (_ row: [String: Any?])->()) throws {
		resetError()
		
		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }
		
		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		
		var keys = [String]()
		for index in 0..<Int(stmt.fieldCount()) {
			let fieldInfo = stmt.fieldInfo(index: index)
			keys.append(fieldInfo?.name ?? "?")
		}
		
		
		if !stmt.execute() {
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }
		
		_ = datos.forEachRow { row in
			var dic = [String: Any?]()
			
			for (key, value) in zip(keys, row) {
				dic[key] = correctData(data: value)
			}
			
			closure(dic)
		}
	}
	
	public func queryAll(_ query:String, args:Any..., closure: (_ row: [String: Any?])->()) throws {
		resetError()

		let stmt:MySQLStmt = MySQLStmt(mysql)
		defer { stmt.close() }

		guard stmt.prepare(statement: query) else {
			lastError = (Int(stmt.errorCode()), "Cannot create statement \(stmt.errorCode()) \(stmt.errorMessage())")
			throw ConnectionError.errorPrepareStatement(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}

		try addParams(stmt, args: args)

        var keys = [String]()
        for index in 0..<Int(stmt.fieldCount()) {
            let fieldInfo = stmt.fieldInfo(index: index)
            keys.append(fieldInfo?.name ?? "?")
        }
        
        
		if !stmt.execute() {
			throw ConnectionError.errorExecute(errorCode: Int(mysql.errorCode()), errorMessage: mysql.errorMessage())
		}
		let datos = stmt.results()
		defer { stmt.freeResult() }

		_ = datos.forEachRow { row in
            var dic = [String: Any?]()
            
            for (key, value) in zip(keys, row) {
                dic[key] = correctData(data: value)
            }

			closure(dic)
		}
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


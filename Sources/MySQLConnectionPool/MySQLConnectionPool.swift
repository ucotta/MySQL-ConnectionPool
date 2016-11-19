//
//  MySQLConnectionPool.swift
//
//  Created by Ubaldo Cotta on 24/10/16.
//
//

import Foundation
import MySQL
import PerfectThread

public class MySQLConnectionPool {
	public static let sharedInstance = MySQLConnectionPool()

	// Connection settings
	private var host:String = "", user:String = "", pass:String = ""
	private var port:Int = 3306, scheme:String?, database:String?

	// Pool management settins and max wait until throw an exception for timeout.
	private var initialSize = 2, maxActive = 20, maxIdle = 4, getTimeout = 5

	// Pool data
	private var totalConnections = 0
	private var activeConnections: [Connection] = []
	private var inactiveConnections: [Connection] = []
	private var lastConnectionId = 0

	private var lock = NSLock()

	// Only can get sharedInstance
	private init() {}

	public func configureConnection(host:String, port:Int?, user:String, pass:String, scheme: String?) {
		self.host = host
		self.user = user
		self.pass = pass
		self.port = port ?? self.port
		self.scheme = scheme
	}

	public func configurePool(initialSize:Int?, maxActive:Int?, maxIdle:Int?, getTimeout:Int?) {
		self.initialSize = initialSize ?? self.initialSize
		self.maxActive = maxActive ?? self.maxActive
		self.maxIdle = maxIdle ?? self.maxIdle
		self.getTimeout = getTimeout ?? self.getTimeout
	}

	public func getConnection() throws -> Connection  {
		let timeStartWaiting = Date()

		// Wait until we have a connection or throw timeout.
		while Int(timeStartWaiting.timeIntervalSinceNow) > -getTimeout {
			if let conn = lockAndGetConnection() {
				if conn.lastError.errorCode == 0 {
					return conn
				}
				// The connection will released in Connection.deinit
				throw ConnectionPoolError.errorConnecting(errorCode: conn.lastError.errorCode, message: conn.lastError.errorMessage)
			}
			Threading.sleep(seconds: 0.50)
		}
		print("timeout getconnnection")
		throw ConnectionPoolError.timeoutWaitingForFreeConnections
	}

	private func lockAndGetConnection() -> Connection? {
		lock.lock()
		defer { lock.unlock() }

		if inactiveConnections.count > 0 {
			let conn = inactiveConnections.removeLast()
			if isAlive(conn: conn) {
				activeConnections.append(conn)
				return conn
			}
			return nil
		}
		if totalConnections < maxActive {
			// Create a new connection
			lastConnectionId += 1
			let conn:Connection = Connection(lastConnectionId, host: host, port: port, user: user, pass: pass, scheme: scheme)

			// Failed connections are discarted later
			if conn.lastError.errorCode == 0 {
				activeConnections.append(conn)
				self.totalConnections += 1
			}
			return conn
		}
		return nil
	}

	public func removeConnection(conn:Connection) {
		lock.lock()
		defer { lock.unlock() }

		if let p = activeConnections.index(of: conn) {
			activeConnections.remove(at: p)
			totalConnections -= 1
		}
	}

	public func returnConnection(conn:Connection) {
		lock.lock()
		defer { lock.unlock() }

		if let p = activeConnections.index(of: conn) {
			activeConnections.remove(at: p)
		}

		// the connection will be release in Connection.deinit.
		if inactiveConnections.count < maxIdle {
			inactiveConnections.insert(conn, at: 0)
		} else {
			totalConnections -= 1
		}
	}

	private func isAlive(conn:Connection) -> Bool {
		do {
			try conn.execute("SELECT now()")
		} catch {
			return false
		}
		return true
	}
	
}



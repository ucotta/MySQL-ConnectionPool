//
//  Errors.swift
//  Paella
//
//  Created by Ubaldo Cotta on 24/10/16.
//
//


public enum ConnectionPoolError : Error {
	case timeoutWaitingForFreeConnections
	case errorConnecting(errorCode:Int, message:String)
}

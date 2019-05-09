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

public enum ConnectionError : Error {
	case fieldTypeNotSupported(fieldRow: Int, fieldData: Any?)
	case errorPrepareStatement(errorCode: Int, errorMessage: String)
	case errorPrepareQuery(errorCode: Int, errorMessage: String)
	case errorExecute(errorCode: Int, errorMessage: String)

	case resultNotContainsCountKey
	case fieldNotFound(field:String, in:String)
}

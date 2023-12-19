//
//  DatabaseHandler.swift
//
//
//  Created by Andi Felder on 12.12.2023.
//

import Foundation
import Vapor
import Fluent

public enum DatabaseErrors {
    case userNotFound
    case emptyTable
    case couldNotSave
    case couldNotDelete
    case couldNotUpdate
    case IDNotFound
}

extension DatabaseErrors: AbortError {
    public var reason: String {
        switch self {
        case .userNotFound:
            return "User not found"
        case .emptyTable:
            return "Table is empty"
        case .couldNotSave:
            return "Could not save"
        case .couldNotDelete:
            return "Could not delete"
        case .couldNotUpdate:
            return "Could not update"
        case .IDNotFound:
            return "ID not found"
        }
    }
    
   public var status: HTTPStatus {
        switch self {
        case .userNotFound:
            return .notFound
        case .emptyTable:
            return .notFound
        case .couldNotSave:
            return .internalServerError
        case .couldNotDelete:
            return .internalServerError
        case .couldNotUpdate:
            return .internalServerError
        case .IDNotFound:
            return .notFound
        }
    }
}


extension FluentKit.Model {
    public static func all(on database: any Database) async throws -> [Self] {
        try await Self.query(on: database).all()
    }

}

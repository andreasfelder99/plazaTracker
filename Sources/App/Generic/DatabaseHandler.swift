//
//  DatabaseHandler.swift
//
//
//  Created by Andi Felder on 12.12.2023.
//

import Foundation
import Vapor
import Fluent


func getAll<T: Model>(onDatabase db: Database) async throws -> [T] {
    return try await T.query(on: db).all()
}

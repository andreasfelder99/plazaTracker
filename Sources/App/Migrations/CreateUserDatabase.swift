//
//  File.swift
//  
//
//  Created by Andi Felder on 27.11.2023.
//

import Foundation
import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            database.enum("userType")
                .case("admin")
                .case("counter")
                .case("restricted")
                .create()
                .map { userType in
                    print("yeet")
                    database.schema("users")
                        .id()
                        .field("name", .string, .required)
                        .field("email", .string, .required)
                        .field("password_hash", .string, .required)
                        .unique(on: "email")
                        .field("userType", userType, .required)
                        .field("created_at", .date)
                        .field("updated_at", .date)
                        .field("deleted_at", .date)
                        .create()
                }
        }

        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}

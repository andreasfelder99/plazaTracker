//
//  File.swift
//  
//
//  Created by Andi Felder on 27.11.2023.
//

import Foundation
import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    @Enum(key: "userType")
    var userType: UserType

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String, userType: UserType = .counter, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.userType = userType
    }
}

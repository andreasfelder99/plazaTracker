//
//  File.swift
//  
//
//  Created by Andi Felder on 27.11.2023.
//

import Foundation
import Vapor
import Fluent

struct UserViewController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let userViewController = routes.grouped("api", "users")
        let passwordProtected = userViewController.grouped(User.credentialsAuthenticator(), User.sessionAuthenticator())
        
        passwordProtected.get(use: getAllHandler(_:))
        passwordProtected.get("me", use: getMeHandler(_:))
        userViewController.post("create", use: createHandler(_:))
        passwordProtected.post("login", use: loginHandler(_:))
    }
    
    func getMeHandler(_ req: Request) throws -> User {
        try req.auth.require(User.self)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: req.db).all()
    }
    
    func loginHandler(_ req: Request) throws -> User {
        try req.auth.require(User.self)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
        
        let user = try User(
            name: create.name,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        
        return user.save(on: req.db).map({user})
    }
  
}

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}

extension User {
    struct displayUser: Content {
        var name: String
        var email: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: ModelSessionAuthenticatable { }

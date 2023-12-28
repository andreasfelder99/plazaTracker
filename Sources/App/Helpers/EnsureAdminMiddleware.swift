//
//  File.swift
//  
//
//  Created by Andi Felder on 19.12.2023.
//

import Vapor

struct EnsureAdminUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.userType == .admin else {
            let context: authErrorContext
            if let error = request.query[Bool.self, at: "error"], error {
                return request.redirect(to: "/index?privilegesError=true")
            }
            throw Abort(.unauthorized, reason: "You need to be an admin to access this page")
        }
        return try await next.respond(to: request)
    }
}

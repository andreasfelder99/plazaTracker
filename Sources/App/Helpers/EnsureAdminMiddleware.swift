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
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}

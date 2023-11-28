//
//  File.swift
//  
//
//  Created by Andi Felder on 27.11.2023.
//

import Foundation
import Vapor

struct EnsureLoginMiddleware: Middleware {
    func respond(to request: Vapor.Request, chainingTo next: Vapor.Responder) -> EventLoopFuture<Response> {
        guard request.auth.get(User.self) != nil else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
    
    
}

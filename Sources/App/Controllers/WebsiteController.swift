//
//  File.swift
//  
//
//  Created by Andi Felder on 21.11.2023.
//

import Foundation
import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        authSessionsRoutes.get("login", use: loginHandler)
        authSessionsRoutes.post("logout", use: logoutHandler)
        
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        credentialsAuthRoutes.post("login", use: loginPostHandler)
        
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("admin", use: adminViewController().index)
        
        authSessionsRoutes.get(use: index)
    }
    func index(req: Request) -> EventLoopFuture<View> {
        var indexContent = IndexContext(title: "Welcome", isLoggedIn: false, username: "", email: "")
        if let user = req.auth.get(User.self) {
            indexContent.isLoggedIn = true
            indexContent.username = user.name
            indexContent.email = user.email
        }
        return req.view.render("index", indexContent)
    }
    
    func loginHandler(_ req: Request) -> EventLoopFuture<View>{
        let context: LoginContext
        
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        
        return req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
        if req.auth.has(User.self){
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            let context = LoginContext(loginError: true)
            return req
                .view
                .render("login", context)
                .encodeResponse(for: req)
        }
    }
    
    func logoutHandler(_ req: Request) -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
}

struct IndexContext: Encodable {
    var title: String
    var isLoggedIn : Bool
    var username: String
    var email: String
}

struct LoginContext: Encodable {
    let title = "logging in.."
    let loginError: Bool
    
    init(loginError: Bool = false){
        self.loginError = loginError
    }
}

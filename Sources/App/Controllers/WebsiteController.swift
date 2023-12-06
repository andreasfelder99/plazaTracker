//
//  File.swift
//
//
//  Created by Andi Felder on 21.11.2023.
//

import Foundation
import Leaf
import Vapor

struct WebsiteController: RouteCollection {
    
    let adminController: AdminViewController
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes.get("newDesign", use: newDesign)
        
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        authSessionsRoutes.get("login", use: loginHandler)
        authSessionsRoutes.post("logout", use: logoutHandler)
        
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        credentialsAuthRoutes.post("login", use: loginPostHandler)
        
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("admin", use: adminController.index)
        protectedRoutes.get("counter", use: CounterViewController().index)
        
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
    
    func newDesign(req: Request) -> EventLoopFuture<View> {
        return req.view.render("newbase")
    }
    
    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: LoginContext
        
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        
        return req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
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
    var isLoggedIn: Bool
    var username: String
    var email: String
}

struct LoginContext: Encodable {
    let title = "Bitte einloggen. Falls du noch keinen Account hast, wende dich an den Administrator."
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

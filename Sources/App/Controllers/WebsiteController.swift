//
//  File.swift
//
//
//  Created by Andi Felder on 21.11.2023.
//

import Foundation
import Leaf
import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    
    let adminController: AdminViewController
    let counterController: CounterViewController
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        
        
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        authSessionsRoutes.get("login", use: loginHandler)
        authSessionsRoutes.post("logout", use: logoutHandler)
        
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        credentialsAuthRoutes.post("login", use: loginPostHandler)
        
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        let adminProtectedRoutes = protectedRoutes.grouped(EnsureAdminUserMiddleware())
        adminProtectedRoutes.get("admin", use: adminController.index)
        protectedRoutes.get("counter", use: counterController.index)
        
        authSessionsRoutes.get(use: index)
    }

    func index(req: Request) async throws -> View {
        var indexContent = await generateLoggedInContext(req)
        return try await req.view.render("index", indexContent)
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

public struct LoggedInContext: Encodable {
    var title: String
    var isLoggedIn: Bool
    var isAdmin = false
    var username: String
    var email: String
    var activeClubNight: ClubNight?
    var liveCapacity = 0
    var clubNights: [ClubNight]?
    var isError: Bool = false
}

struct LoginContext: Encodable {
    let title = "Bitte einloggen. Falls du noch keinen Account hast, wende dich an den Administrator."
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct authErrorContext: Encodable {
    let title = "Not sufficient permissions to enter this part of the webapp!"
    let permissionError: Bool
    
    init(permissionError: Bool) {
        self.permissionError = permissionError
    }
}

public func generateLoggedInContext(_ req: Request) async -> LoggedInContext {
    var loggedInContext = LoggedInContext(title: "", isLoggedIn: false, username: "", email: "")
    
    do {
        if let user = req.auth.get(User.self) {
            loggedInContext.isLoggedIn = true
            loggedInContext.username = user.name
            loggedInContext.email = user.email
            
            if user.userType == .admin {
                loggedInContext.isAdmin = true
            }
        }
        
        let clubNights = try await req.db.query(ClubNight.self).sort( \.$date).sort(\.$id).all()
        let activeClubNight = clubNights.filter { $0.isActive }.first
        
        loggedInContext.clubNights = clubNights
        loggedInContext.activeClubNight = activeClubNight
        
        return loggedInContext
    } catch {
        return loggedInContext
    }
}

public func getActiveNight(db: Database) async -> Int {
    do {
        let nights = try await db.query(ClubNight.self).all()
        let activeNight = nights.filter { $0.isActive }.first
        return activeNight?.currentGuests ?? 0
    } catch {
        print("Error at getActiveNight")
    }
    return 0
}

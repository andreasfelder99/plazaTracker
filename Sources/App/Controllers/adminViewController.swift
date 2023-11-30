//
//  File.swift
//
//
//  Created by Andreas Felder on 20.11.2023.
//

import Foundation
import Vapor
import Fluent

struct adminViewController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.post("api", "clubnights", "create", use: createHandler)
        
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("admin", ":clubnightID", use: editClubNightViewHandler)
        protectedRoutes.post("admin", ":clubnightID", use: updateHandler)
    }
    
    func index(_ req: Request) -> EventLoopFuture<View> {
        if let user = req.auth.get(User.self) {
            return getAllHandler(req).flatMap { clubNights in
                return indexView(with: clubNights, for: user, on: req)
            }.flatMapError { error in
                print("Error fetching club nights: \(error)")
                return req.view.render("admin", AdminContext(isLoggedIn: false, username: "", clubNights: nil))
            }
        } else {
            let adminContext = AdminContext(isLoggedIn: false, username: "", clubNights: nil)
            return req.view.render("admin", adminContext)
        }
    }
    
    private func indexView(with clubNights: [ClubNight], for user: User, on req: Request) -> EventLoopFuture<View> {
        var adminContext = AdminContext(isLoggedIn: true, username: user.name, clubNights: clubNights)
        return req.view.render("admin", adminContext)
    }
    
    func editClubNightViewHandler(_ req: Request) -> EventLoopFuture<View> {
        return ClubNight
            .find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { clubNight in
                let context = UpdateContext(selectedClubNight: clubNight)
                return req.view.render("editClubNight", context)
            }
        
    }
    func getAllHandler(_ req: Request) -> EventLoopFuture<[ClubNight]> {
        ClubNight.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<ClubNight> {
        let clubNight = try req.content.decode(ClubNight.self)
        return clubNight.save(on: req.db).map{ clubNight }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<ClubNight> {
        ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<ClubNight> {
        let updatedClubNight = try req.content.decode(ClubNight.self)
        
        return ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { clubNight in
                clubNight.eventName = updatedClubNight.eventName
                clubNight.isActive = updatedClubNight.isActive
                clubNight.totalGuests = updatedClubNight.totalGuests
                
                return clubNight.save(on: req.db).map { clubNight }
            }
    }
}

struct AdminContext: Encodable {
    var isLoggedIn: Bool
    var username: String
    var clubNights: [ClubNight]?
}

struct UpdateContext: Encodable {
    var selectedClubNight: ClubNight
    
}

//
//  File.swift
//
//
//  Created by Andreas Felder on 20.11.2023.
//

import Fluent
import Foundation
import Vapor
import Leaf

struct AdminViewController: RouteCollection {
    
    let counterSystem: CounterSystem
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("api", "clubnights", "create", use: createHandler)
        routes.post("api", "clubnights", ":clubnightID", "activate", use: activateClubNightHandler)
        
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.get("admin", ":clubnightID", use: editClubNightViewHandler)
        protectedRoutes.post("admin", ":clubnightID", use: updateHandler)
        protectedRoutes.post("admin", "new", use: createHandler)
    }
    
    func index(_ req: Request) -> EventLoopFuture<View> {
        if let user = req.auth.get(User.self) {
            return getAllHandler(req).flatMap { clubNights in
                // Fetch active night
                let activeNight = clubNights.filter { $0.isActive }.first
                
                
                let adminContext = AdminContext(isLoggedIn: true, username: user.name, clubNights: clubNights, currentClubNight: activeNight)
                
                return indexView(with: adminContext, on: req)
            }.flatMapError { error in
                print("Error fetching club nights: \(error)")
                print(String(reflecting: error))
                return req.view.render("newadmin", AdminContext(isLoggedIn: false, username: "", clubNights: nil, currentClubNight: nil))
            }
        } else {
            let adminContext = AdminContext(isLoggedIn: false, username: "", clubNights: nil, currentClubNight: nil)
            return req.view.render("newadmin", adminContext)
        }
    }
    
    private func indexView(with adminContext: AdminContext, on req: Request) -> EventLoopFuture<View> {
        return req.view.render("newadmin", adminContext)
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
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let clubNight = try req.content.decode(ClubNight.self)
        return clubNight.save(on: req.db)
            .map { _ in
                // Redirect to /admin after creating a new ClubNight
                req.redirect(to: "/admin")
            }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<ClubNight> {
        ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let updatedClubNight = try req.content.decode(ClubNight.self)
        
        return ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { clubNight in
                clubNight.eventName = updatedClubNight.eventName
                clubNight.isActive = updatedClubNight.isActive
                clubNight.totalGuests = updatedClubNight.totalGuests
                
                if updatedClubNight.isActive {
                    setAllOtherNightsToDisabled(req, id: updatedClubNight.id ?? UUID())
                }
                
                clubNight.update(on: req.db)
                
                // Redirect to /admin after updating the club night
                return req.eventLoop.future(req.redirect(to: "/admin"))
            }
    }
    
    func activateClubNightHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        return ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { clubnight in
                clubnight.isActive = true
                clubnight.update(on: req.db)
                setAllOtherNightsToDisabled(req, id: clubnight.id ?? UUID())
                self.counterSystem.counter.currentClubNight = clubnight
                self.counterSystem.counter.currentCount = 0
                return req.eventLoop.future(req.redirect(to: "/admin"))
            }
    }
    
    func setAllOtherNightsToDisabled(_ req: Request, id: UUID) {
        ClubNight.query(on: req.db)
            .all()
            .map { clubNights in
                clubNights.forEach { night in
                    if night.id != id {
                        night.isActive = false
                        night.update(on: req.db)
                    }
                }
            }
    }
}
struct AdminContext: Encodable {
    var isLoggedIn: Bool
    var username: String
    var clubNights: [ClubNight]?
    var currentClubNight: ClubNight?
}

struct ActivateButton: Content {
    var activate: Bool
}

struct UpdateContext: Encodable {
    var selectedClubNight: ClubNight
}

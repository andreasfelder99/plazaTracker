//
//  File.swift
//
//
//  Created by Andreas Felder on 20.11.2023.
//

//TODO: JS checkbox fixen, event aktiv fixen, leben in griff bekommen, heroku push
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
        protectedRoutes.get("admin", "new", use: createViewHandler)
        
        protectedRoutes.post("admin", ":clubnightID", use: updateHandler)
        protectedRoutes.post("admin", "new", use: createHandler)
    }
    
    func index(_ req: Request) async throws -> View {
        let context = await generateLoggedInContext(req)
        guard let id = context.activeClubNight?.id else {
            return try await req.view.render("newadmin", context)
        }
        setAllOtherNightsToDisabled(req, id: id)
        return try await req.view.render("newadmin", context)
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
    
    //TODO: Change status of all other events after creating a new one
    func createHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let clubNight = try req.content.decode(ClubNight.self)
        return clubNight.save(on: req.db)
            .map { _ in
                // Redirect to /admin after creating a new ClubNight
                setAllOtherNightsToDisabled(req, id: clubNight.id!)
                return req.redirect(to: "/admin")
            }
       
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<ClubNight> {
        ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func createViewHandler(_ req: Request) async throws -> View {
        let context = CreateContext(isCreating: true)
        return try await req.view.render("editClubNight", context)
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
                
                _ = clubNight.update(on: req.db)
                
                // Redirect to /admin after updating the club night
                return req.eventLoop.future(req.redirect(to: "/admin"))
            }
    }
    
    func activateClubNightHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        return ClubNight.find(req.parameters.get("clubnightID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { clubnight in
                clubnight.isActive = true
                _ = clubnight.update(on: req.db)
                setAllOtherNightsToDisabled(req, id: clubnight.id ?? UUID())
                self.counterSystem.counter.currentClubNight = clubnight
                self.counterSystem.counter.currentCount = clubnight.currentGuests ?? 0
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
                        _ = night.update(on: req.db)
                    }
                }
            }
    }
}

struct ActivateButton: Content {
    var activate: Bool
}

struct UpdateContext: Encodable {
    var selectedClubNight: ClubNight
}

struct CreateContext: Encodable {
    var isCreating: Bool
}

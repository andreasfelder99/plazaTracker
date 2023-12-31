//
//  File.swift
//
//
//  Created by Andreas Felder on 20.11.2023.
//

import Fluent
import Foundation
import Leaf
import Vapor

struct AdminViewController: RouteCollection {
    let counterSystem: CounterSystem
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("api", "clubnights", "create", use: createHandler)
        routes.post("api", "clubnights", ":clubnightID", "activate", use: activateClubNightHandler)
        
        let protectedRoutes = routes.grouped(User.redirectMiddleware(path: "/login"))
        let adminProtectedRoutes = protectedRoutes.grouped(EnsureAdminUserMiddleware())
        adminProtectedRoutes.get("admin", ":clubnightID", use: editClubNightViewHandler)
        adminProtectedRoutes.get("admin", "new", use: createViewHandler)
        adminProtectedRoutes.get("admin", "getLiveData", use: liveGraphDataHandler)
        
        adminProtectedRoutes.post("admin", ":clubnightID", use: updateHandler)
        adminProtectedRoutes.post("admin", "new", use: createHandler)
        adminProtectedRoutes.post("admin", ":clubnightID", "delete", use: deleteHandler)
    }
    
    func index(_ req: Request) async throws -> View {
        var context = await generateLoggedInContext(req)
        guard let id = context.activeClubNight?.id else {
            return try await req.view.render("newadmin", context)
        }
        setAllOtherNightsToDisabled(req, id: id)
        context.liveCapacity = Int((Double(context.activeClubNight!.currentGuests!) / Double(context.activeClubNight!.totalGuests)) * 100)
        return try await req.view.render("newadmin", context)
    }
    
    func deleteHandler(_ req: Request) async throws -> Response {
        guard let id = req.parameters.get("clubnightID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        do {
            if let clubNight = try await ClubNight.find(id, on: req.db) {
                try await clubNight.delete(on: req.db)
            }
            return req.redirect(to: "/admin")
        } catch {
            throw Abort(.internalServerError)
        }
    }
    
    func liveGraphDataHandler(_ req: Request) async throws -> GetTrackingData {
        do {
            if let activeClubNightID = try await ClubNight.query(on: req.db).filter(\.$isActive == true).first()?.id {
                guard let currentData = try await TrackingData.query(on: req.db).filter(\.$clubNight.$id == activeClubNightID).first() else {
                    throw Abort(.notFound)
                }
                return GetTrackingData(clubNightID: currentData.$clubNight.id, trackingDataID: currentData.id!, trackingData: currentData.nightData)
            }
            
        } catch {
            throw Abort(.notFound)
        }
        throw Abort(.notFound)
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

    func getAllHandler(_ req: Request) async -> [ClubNight] {
        do {
            return try await ClubNight.all(on: req.db)
        } catch {
            req.logger.report(error: error)
            return []
        }
    }
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
                clubNight.currentGuests = updatedClubNight.currentGuests ?? 0
                
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

struct GetTrackingData: Content {
    let clubNightID: UUID
    let trackingDataID: UUID
    let trackingData: NightData
}

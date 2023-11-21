//
//  File.swift
//  
//
//  Created by Andreas Felder on 20.11.2023.
//

import Foundation
import Vapor
import Fluent

struct ClubNightController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let clubNightRoutes = routes.grouped("api", "clubnights")
        
        clubNightRoutes.get(use: getAllHandler)
        clubNightRoutes.get(":clubnightID", use: getHandler)
        
        clubNightRoutes.put(":clubnightID", use: updateHandler)
        
        clubNightRoutes.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[ClubNight]> {
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

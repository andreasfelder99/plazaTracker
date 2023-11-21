//
//  File.swift
//  
//
//  Created by Andreas Felder on 20.11.2023.
//

import Foundation
import Fluent

struct CreateClubNight: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights")
            .id()
            .field("date", .string, .required)
            .field("eventName", .string, .required)
            .field("isActive", .bool, .required)
            .field("totalGuests", .int, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights").delete()
    }
}

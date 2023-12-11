//
//  File.swift
//  
//
//  Created by Andi Felder on 07.12.2023.
//

import Foundation
import Fluent

struct CreateClubNightData: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnight_data")
            .id()
            .field("clubnight_id", .uuid, .required, .references("clubnights", "id"))
            .field("night_data", .dictionary(of: .int), .required)
            .field("maximum_count", .int, .sql(.default(0)))
            .field("created_at", .date)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .create()
            
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnight_data").delete()
    }
    
    
}

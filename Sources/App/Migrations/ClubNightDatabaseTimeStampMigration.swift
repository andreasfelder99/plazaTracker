//
//  File.swift
//  
//
//  Created by Andi Felder on 27.12.2023.
//

import Foundation
import Fluent


struct ClubNightDatabaseTimeStampMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights")
            .field("created_at", .date)
            .field("updated_at", .date)
            .field("deleted_at", .date)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights")
            .deleteField("created_at")
            .deleteField("updated_at")
            .deleteField("deleted_at")
            .update()
    }
}

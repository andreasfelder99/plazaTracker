//
//  File.swift
//
//
//  Created by Andi Felder on 04.12.2023.
//

import Fluent
import Foundation

struct ClubNightUpdateCurrentGuestsMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights")
            .deleteField("currentGuests")
            .field("currentGuests", .int, .sql(.default(0)))
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("clubnights").delete()
    }
}

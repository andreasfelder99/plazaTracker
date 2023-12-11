//
//  File.swift
//  
//
//  Created by Andi Felder on 07.12.2023.
//

import Foundation
import Vapor
import Fluent

final class TrackingData: Model {
    static let schema = "clubnight_data"
    
    @ID
    var id: UUID?
    
    @Parent(key: "clubnight_id")
    var clubNight: ClubNight
    
    @Field(key: "night_data")
    var nightData: NightData
    
    @OptionalField(key: "maximum_count")
    var maximumCount: Int?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, clubNightID: ClubNight.IDValue, nightData: NightData, maximumCount: Int? = 0, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) {
        self.id = id
        self.$clubNight.id = clubNightID
        self.nightData = nightData
    }
}

struct NightData: Codable {
    var data: [String:Int]
}

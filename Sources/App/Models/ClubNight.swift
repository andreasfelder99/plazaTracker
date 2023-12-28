//
//  File.swift
//  
//
//  Created by Andreas Felder on 20.11.2023.
//

import Foundation
import Vapor
import Fluent

final class ClubNight: Model {
    static let schema = "clubnights"
    
    @ID
    var id: UUID?
    
    @Field(key: "date")
    var date: String
    
    @Field(key: "eventName")
    var eventName: String
    
    @Field(key: "isActive")
    var isActive: Bool
    
    @Field(key: "totalGuests")
    var totalGuests: Int
    
    @OptionalField(key: "currentGuests")
    var currentGuests: Int?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, date: String, eventName: String, isActive: Bool, totalGuests: Int, currentGuests: Int?, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) {
        self.id = id
        self.eventName = eventName
        self.isActive = isActive
        self.totalGuests = totalGuests
        self.currentGuests = currentGuests ?? 0
    }
    
}

extension ClubNight: Content { }

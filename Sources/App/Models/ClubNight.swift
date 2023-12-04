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
    
    
    
    
    init() {}
    
    init(id: UUID? = nil, date: String, eventName: String, isActive: Bool, totalGuests: Int, currentGuests: Int?) {
        self.id = id
        self.eventName = eventName
        self.isActive = isActive
        self.totalGuests = totalGuests
        self.currentGuests = currentGuests ?? 0
    }
    
}

extension ClubNight: Content { }

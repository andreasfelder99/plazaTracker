//
//  File.swift
//  
//
//  Created by Andi Felder on 11.12.2023.
//

import Foundation
import Leaf

enum CurrentCapacityError: Error {
    case capacityNotFound
}

struct CurrentCapacityTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        guard let currentCapacity = ctx.data["liveCapacity"]?.int else {
            throw CurrentCapacityError.capacityNotFound
        }
        return LeafData.string("<div class=\"progress progress-sm\"> <div class=\"progress-bar bg-info\" aria-valuenow=\"\(currentCapacity)\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: \(currentCapacity)%;\"><span class=\"visually-hidden\">\(currentCapacity)%</span></div></div>")
    }
    
    
}

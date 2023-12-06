//
//  File.swift
//
//
//  Created by Andi Felder on 01.12.2023.
//

import Fluent
import Foundation
import Vapor

struct CounterViewController: RouteCollection {
    let counterSystem: CounterSystem
    
    func boot(routes: RoutesBuilder) throws {}
    
    func index(req: Request) async throws -> View {
        var indexContent = await generateLoggedInContext(req)
        return try await req.view.render("counter", indexContent)
    }
}

class Counter {
    @ThreadSafe
    var currentClubNight: ClubNight?
    let eventLoop: EventLoop
    
    @ThreadSafe
    var currentCount = 0
    
    init(eventLoop: EventLoop, database: Database) {
        self.eventLoop = eventLoop
        eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(10)) { _ in
            if let currentClubNight = self.currentClubNight {
                currentClubNight.currentGuests = self.currentCount
                return currentClubNight.save(on: database)
            } else {
                return eventLoop.future()
            }
            // This is where you can update the database
        }
    }
    
    func increaseCounter() -> Int {
        self.currentCount += 1
        return self.currentCount
    }
    
    func decreaseCounter() -> Int {
        if self.currentCount > 0 {
            self.currentCount -= 1
        }
        return self.currentCount
    }
}

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
    
    func boot(routes: RoutesBuilder) throws { }
    
    func index(req: Request) throws -> EventLoopFuture<View> {
        var indexContent = IndexContext(title: "Counter", isLoggedIn: false, username: "", email: "")
        if let user = req.auth.get(User.self) {
            indexContent.isLoggedIn = true
            indexContent.username = user.name
            indexContent.email = user.email
            
            guard let activeClubNight = counterSystem.counter.currentClubNight else {
                let errorContext = ErrorContext(errorMessage: "Kein aktives Event vom Administrator ausgewählt!")
                return req.view.render("counter", errorContext)
            }
            
            let counterContext = CounterContext(indexContext: indexContent, activeClubNight: activeClubNight)
            return req.view.render("counter", counterContext)
        } else {
            return req.view.render("counter", ErrorContext(errorMessage: "fail"))
        }
    }
}

struct ErrorContext: Encodable {
    let errorMessage: String
    let isError = true
}

struct CounterContext: Encodable {
    var indexContext: IndexContext
    var activeClubNight: ClubNight
    let isError = false
}

class Counter {

    @ThreadSafe
    var currentClubNight: ClubNight?
    let eventLoop: EventLoop
    
    @ThreadSafe
    var currentCount = 0
    
    init(eventLoop: EventLoop, database: Database) {
        self.eventLoop = eventLoop
        eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(10)) { task in
            if let currentClubNight = self.currentClubNight {
                if currentClubNight.currentGuests! > self.currentCount {
                    self.currentCount = currentClubNight.currentGuests!
                } else {
                    currentClubNight.currentGuests = self.currentCount
                }
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

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
    func boot(routes: RoutesBuilder) throws {
        routes.get("counter", use: index)
    }
    
    func index(req: Request) throws -> EventLoopFuture<View> {
        var indexContent = IndexContext(title: "Counter", isLoggedIn: false, username: "", email: "")
        CounterManager.shared.counterContext = CounterViewContext(indexContext: indexContent)
        if let user = req.auth.get(User.self) {
            indexContent.isLoggedIn = true
            indexContent.username = user.name
            indexContent.email = user.email
        }
        
        return ClubNight.query(on: req.db)
            .filter(\.$isActive == true)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { clubNight in
                CounterManager.shared.currentClubNight = clubNight
                CounterManager.shared.webSocketURL! += "\(clubNight.id!)"
            }
            .flatMapThrowing {
                if CounterManager.shared.currentClubNight == nil {
                    throw Abort(.notFound)
                }
            }
            .flatMap {
                req.view.render("counter", CounterManager.shared)
            }
    }
}

struct CounterViewContext: Encodable {
    let indexContext: IndexContext
}

class Counter {
    @ThreadSafe
    var currentCount = 0
    
    @ThreadSafe
    var currentClubNight: ClubNight?
    let eventLoop: EventLoop
    
    init(eventLoop: EventLoop, database: Database) {
        self.eventLoop = eventLoop
        eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(10)) { task in
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

class CounterManager: Encodable {
    static var shared = CounterManager()
    
    var counterContext: CounterViewContext?
    var currentClubNight: ClubNight?
    var webSocketURL = Environment.get("WEBSOCKET")
    
    func increaseCounter(req: Request) {
        currentClubNight?.currentGuests! += 1
        updateCounter(req: req)
    }
    
    func decreaseCounter(req: Request) {
        if !(currentClubNight?.currentGuests! == 0) {
            currentClubNight?.currentGuests! -= 1
            updateCounter(req: req)
        }
    }
    
    private func updateCounter(req: Request) {
        guard let currentClubNight = CounterManager.shared.currentClubNight else { return }
        
        _ = ClubNight.query(on: req.db)
            .filter(\.$id == currentClubNight.id!)
            .set(\.$currentGuests, to: currentClubNight.currentGuests!)
            .update()
            .map { _ in
                print("Counter updated")
            }
            .flatMapError { error in
                print("Failed to update counter: \(error)")
                return req.eventLoop.makeFailedFuture(error)
            }
    }
    
    func handleCounter(isIncreasing: Bool, req: Request) {
        if isIncreasing {
            increaseCounter(req: req)
        } else {
            decreaseCounter(req: req)
        }
    }
}

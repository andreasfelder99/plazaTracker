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
    var currentDataElement: TrackingData?
    let eventLoop: EventLoop
    
    @ThreadSafe
    var currentCount = 0
    var nightData = NightData(data: ["INIT": 0])
    
    init(eventLoop: EventLoop, database: Database) {
        print("1")
        self.eventLoop = eventLoop
        eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(10)) { _ in
            if let currentClubNight = self.currentClubNight {
                currentClubNight.currentGuests = self.currentCount
                if let currentDataElement = self.currentDataElement {
                    self.createDataEntry()
                    currentDataElement.nightData = self.nightData
                    print(currentDataElement.nightData)
                    _ = currentDataElement.save(on: database)
                } else {
                    guard let activeClubNightID = currentClubNight.id else {
                        return eventLoop.future()
                    }
                    self.currentDataElement = TrackingData(clubNightID: activeClubNightID, nightData: self.nightData)
                    _ = self.currentDataElement!.save(on: database)
                }
                _ = currentClubNight.save(on: database)
                
            } else {
                return eventLoop.future()
            }
            return eventLoop.future()
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
    
    func createDataEntry() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = df.string(from: date)
        
        print(dateString)
        
        self.nightData.data.updateValue(self.currentCount, forKey: dateString)
    }
}

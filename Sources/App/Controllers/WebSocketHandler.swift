//
//  File.swift
//
//
//  Created by Andi Felder on 04.12.2023.
//

import Foundation
import Vapor

struct Connect: Codable {
    let connect: Bool
}

import Fluent

class CounterSystem {
    @ThreadSafe
    var clients: [UUID: WebSocket]
    let counter: Counter

    init(eventLoop: EventLoop, database: Database) {
        self.clients = [:]
        self.counter = Counter(eventLoop: eventLoop, database: database)
    }

    func connect(_ ws: WebSocket, _ req: Request) {
        let id = UUID()
        
        ws.onText { ws, text in
            if text == "INITIATE" {
                self.clients[id] = ws
                print("Handshake received from \(id.uuidString)")
            }
            else if text == "INCREASE" {
                let newCount = self.counter.increaseCounter()
                self.notify(newCount: newCount)
            } else if text == "DECREASE" {
                let newCount = self.counter.decreaseCounter()
                self.notify(newCount: newCount)
            }
        }
        
        _ = ws.onClose.always { _ in
            self.clients.removeValue(forKey: id)
        }
    }
    
    func notify(newCount: Int) {
        for (_, socket) in self.clients {
            socket.send("\(newCount)")
        }
    }
}

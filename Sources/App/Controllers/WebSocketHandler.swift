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
        
        ws.pingInterval = .seconds(10)
        
        ws.onText { ws, text in
            if text == "INITIATE" {
                self.clients[id] = ws
                print("Handshake received from \(id.uuidString)")
            }
            else if text == "INCREASE" {
                let newCount = self.counter.increaseCounter()
                self.notifyCounters(newCount: newCount)
            } else if text == "DECREASE" {
                let newCount = self.counter.decreaseCounter()
                self.notifyCounters(newCount: newCount)
                
            }
        }
        
        ws.onPing { socket, data in
            print("ping received")
        }
        
        ws.onPong { socket, data in
            socket.sendPing()
        }
        
        _ = ws.onClose.always { _ in
            self.clients.removeValue(forKey: id)
        }
    }
    
    func notifyCounters(newCount: Int) {
        for (_, socket) in self.clients {
            socket.send("\(newCount)")
        }
    }
}


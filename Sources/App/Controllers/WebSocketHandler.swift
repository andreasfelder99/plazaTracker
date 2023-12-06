//
//  File.swift
//
//
//  Created by Andi Felder on 04.12.2023.
//

import Dispatch
import Foundation
import Vapor

struct WebSocketHandler: RouteCollection {
    var websockets: [UUID: WebSocket] = [:]
    func boot(routes: Vapor.RoutesBuilder) throws {}

    func handleWebSocket(req: Request, ws: WebSocket) {
        print("Connection established")
        ws.onText { ws, text in
            switch text {
            case "increase", "decrease":
                CounterManager.shared.handleCounter(isIncreasing: text == "increase", req: req)

                // Send updated data in JSON format
                if let currentClubNight = CounterManager.shared.currentClubNight {
                    let response = WebSocketResponse(currentClubNight: currentClubNight)
                    do {
                        let jsonData = try JSONEncoder().encode(response)
                        ws.send(String(data: jsonData, encoding: .utf8) ?? "")
                        req.redis.publish(jsonData, to: "counter-channel")
                    } catch {
                        print("Failed to encode JSON: \(error)")
                    }
                }

            default:
                print("")
            }
        }
    }
}

struct WebSocketResponse: Encodable {
    let currentClubNight: ClubNight
}

open class WebSocketClient {
    open var id: UUID
    open var socket: WebSocket

    public init(id: UUID, socket: WebSocket) {
        self.id = id
        self.socket = socket
    }
}

open class WebsocketClients {
    var eventLoop: EventLoop
    var storage: [UUID: WebSocketClient]

    var active: [WebSocketClient] {
        self.storage.values.filter { !$0.socket.isClosed }
    }

    init(eventLoop: EventLoop, clients: [UUID: WebSocketClient] = [:]) {
        self.eventLoop = eventLoop
        self.storage = clients
    }

    func add(_ client: WebSocketClient) {
        self.storage[client.id] = client
    }

    func remove(_ client: WebSocketClient) {
        self.storage[client.id] = nil
    }

    func find(_ uuid: UUID) -> WebSocketClient? {
        self.storage[uuid]
    }

    deinit {
        let futures = self.storage.values.map { $0.socket.close() }
        try! self.eventLoop.flatten(futures).wait()
    }
}

struct WebsocketMessage<T: Codable>: Codable {
    let client: UUID
    let data: T
}

extension ByteBuffer {
    func decodeWebsocketMessage<T: Codable>(_ type: T.Type) -> WebsocketMessage<T>? {
        try? JSONDecoder().decode(WebsocketMessage<T>.self, from: self)
    }
}

struct Connect: Codable {
    let connect: Bool
}

final class CounterUser: WebSocketClient {
    struct Status: Codable {
        var id: UUID!
        var username: String
        var clubNight: ClubNight?
        var catcher: Bool = false
    }

    var status: Status
    var increasPressed: Bool = false
    var decreasePressed: Bool = false
    public init(id: UUID, socket: WebSocket, status: Status) {
        self.status = status
        self.status.id = id
        super.init(id: id, socket: socket)
    }

    func update(_ input: CounterInput) {
        switch input.button {
        case .increase:
            print("increase")
            self.increasPressed = input.isPressed
        case .decrease:
            print("decrease")
            self.decreasePressed = input.isPressed
        }
    }

    func updateStatus() {
        if self.increasPressed {
            print("increase2")
            self.status.clubNight?.currentGuests! += 1
        }
        if self.decreasePressed {
            print("dec2")
            if (self.status.clubNight?.currentGuests!)! >= 1 {
                print("dec3")
                self.status.clubNight?.currentGuests! -= 1
            }
        }
    }
}

struct CounterInput: Codable {
    enum Button: String, Codable {
        case increase
        case decrease
    }

    let button: Button
    let isPressed: Bool
}

import Fluent

class CounterSystem {
//    var clients: WebsocketClients

//    var timer: DispatchSourceTimer
    
    @ThreadSafe
    var clients: [UUID: WebSocket]
    let counter: Counter

    init(eventLoop: EventLoop, database: Database) {
        self.clients = [:]
        self.counter = Counter(eventLoop: eventLoop, database: database)
//
//        self.timer = DispatchSource.makeTimerSource()
//        self.timer.setEventHandler { [unowned self] in
//            self.notify()
//        }
//        self.timer.schedule(deadline: .now() + .milliseconds(1000), repeating: .milliseconds(1000))
//        self.timer.activate()
    }

    func connect(_ ws: WebSocket, _ req: Request) {
        let id = UUID()
        
        ws.onBinary { [unowned self] ws, buffer in
            
            if let _ = buffer.decodeWebsocketMessage(Connect.self) {
                self.clients[id] = ws
//                let catcher = self.clients.storage.values
//                    .compactMap { $0 as? CounterUser }
//                    .filter { $0.status.catcher }
//                    .isEmpty
//
//                let counter = CounterUser(id: msg.client, socket: ws, status: .init(username: "", clubNight: CounterManager.shared.currentClubNight!, catcher: catcher))
//                self.clients.add(counter)
//
//                if
//                    let msg = buffer.decodeWebsocketMessage(CounterInput.self),
//                    let counter = self.clients.find(msg.client) as? CounterUser
//                {
//                    print("1")
//                    counter.update(msg.data)
//                }
            }
        }
        
        ws.onText { ws, text in
            if text == "INCREASE" {
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
            socket.send("New Count: \(newCount)")
        }
    }

//    func notify() {
//        let counters = self.clients.active.compactMap { $0 as? CounterUser }
//        guard !counters.isEmpty else {
//            return
//        }
//        print(clients.storage.values)
//
//        let counterUpdate = counters.map { counter -> CounterUser.Status in
//            counter.updateStatus()
//
//            counters.forEach { otherCounter in
//                guard otherCounter.id != counter.id,
//                      counter.status.catcher || otherCounter.status.catcher,
//                      otherCounter.status.clubNight?.currentGuests! != counter.status.clubNight?.currentGuests!
//                else {
//                    //print("2")
//                    return
//                }
//                otherCounter.status.catcher = !otherCounter.status.catcher
//                counter.status.catcher = !counter.status.catcher
//            }
//            return counter.status
//        }
//        let data = try! JSONEncoder().encode(counterUpdate)
//        counters.forEach { counter in
//            //print("3")
//            counter.socket.send([UInt8](data))
//        }
//    }

//    deinit {
//        self.timer.setEventHandler {}
//        self.timer.cancel()
//    }
}

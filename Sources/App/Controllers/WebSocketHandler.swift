//
//  File.swift
//
//
//  Created by Andi Felder on 04.12.2023.
//

import Foundation
import Vapor

struct WebSocketHandler: RouteCollection {
    var websockets: [UUID: WebSocket] = [:]
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes.webSocket("session", ":sessionID") { req, ws in
            handleWebSocket(req: req, ws: ws)
        }
    }

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

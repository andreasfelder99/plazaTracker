//
//  File.swift
//
//
//  Created by Andi Felder on 04.12.2023.
//

import Foundation
import Vapor

struct WebSocketHandler: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes.webSocket("session", ":sessionID") { req, ws in
            handleWebSocket(req: req, ws: ws)
        }
    }

    func handleWebSocket(req: Request, ws: WebSocket) {}
}

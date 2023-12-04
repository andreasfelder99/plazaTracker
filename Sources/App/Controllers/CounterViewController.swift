//
//  File.swift
//
//
//  Created by Andi Felder on 01.12.2023.
//

import Foundation
import Vapor

struct CounterViewController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("counter", use: index)
    }
    
    func index(req: Request) -> EventLoopFuture<View> {
        var indexContent = IndexContext(title: "Counter", isLoggedIn: false, username: "", email: "")
        var counterContent = CounterViewContext(indexContext: indexContent, sessionToken: "", currentClubNight: nil)
        if let user = req.auth.get(User.self) {
            indexContent.isLoggedIn = true
            indexContent.username = user.name
            indexContent.email = user.email
        }
        
        return req.view.render("counter", indexContent)
    }
}

struct CounterViewContext: Encodable {
    let indexContext: IndexContext
    var sessionToken: String
    var currentClubNight: [ClubNight]?
}

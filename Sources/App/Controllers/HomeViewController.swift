//
//  File.swift
//  
//
//  Created by Andi Felder on 21.11.2023.
//

import Foundation
import Vapor
import Leaf

struct HomeViewController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        routes.get(use: index)
    }
  func index(req: Request) -> EventLoopFuture<View> {
      let context = IndexContext(title: "LMAO")
      return req.view.render("index", context)
  }
}

struct IndexContext: Encodable {
  let title: String
}

import Fluent
import Vapor

func routes(_ app: Application) throws {
    let homeViewController = WebsiteController()
    try app.register(collection: homeViewController)
    
    let userViewController = UserViewController()
    try app.register(collection: userViewController)
    
    let clubNightController = AdminViewController()
    try app.register(collection: clubNightController)
    
    let webSocketController = WebSocketHandler()
    try app.register(collection: webSocketController)
    
    
}

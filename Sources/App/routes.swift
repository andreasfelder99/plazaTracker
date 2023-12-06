import Fluent
import Vapor

func routes(_ app: Application, counterSystem: CounterSystem) throws {
    let clubNightController = AdminViewController(counterSystem: counterSystem)
    try app.register(collection: clubNightController)
    
    
    let homeViewController = WebsiteController(adminController: clubNightController)
    try app.register(collection: homeViewController)
    
    let userViewController = UserViewController()
    try app.register(collection: userViewController)
    
    let webSocketController = WebSocketHandler()
    try app.register(collection: webSocketController)
    
    
}

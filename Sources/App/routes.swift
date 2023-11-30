import Fluent
import Vapor

func routes(_ app: Application) throws {
    let homeViewController = WebsiteController()
    try app.register(collection: homeViewController)
    
    let userViewController = UserViewController()
    try app.register(collection: userViewController)
    
    let clubNightController = adminViewController()
    try app.register(collection: clubNightController)
}

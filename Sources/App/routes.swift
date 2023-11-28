import Fluent
import Vapor

func routes(_ app: Application) throws {
    let homeViewController = HomeViewController()
    try app.register(collection: homeViewController)
    
    let userViewController = UserViewController()
    try app.register(collection: userViewController)
    
    let clubNightController = ClubNightController()
    try app.register(collection: clubNightController)
}

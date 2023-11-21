import Fluent
import Vapor

func routes(_ app: Application) throws {
    let clubNightController = ClubNightController()
    try app.register(collection: clubNightController)
}

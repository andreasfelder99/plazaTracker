import Fluent
import Vapor

func routes(_ app: Application, counterSystem: CounterSystem) throws {
    let clubNightController = AdminViewController(counterSystem: counterSystem)
    try app.register(collection: clubNightController)
    
    let counterViewController = CounterViewController(counterSystem: counterSystem)
    try app.register(collection: counterViewController)
    
    let homeViewController = WebsiteController(adminController: clubNightController, counterController: counterViewController)
    try app.register(collection: homeViewController)
    
    
    
    let userViewController = UserViewController()
    try app.register(collection: userViewController)
    
    
}

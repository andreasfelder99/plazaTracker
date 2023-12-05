import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())
    
    if var config = Environment.get("DATABASE_URL")
        .flatMap(URL.init)
        .flatMap(SQLPost.init) {
      config.tlsConfiguration = .forClient(
        certificateVerification: .none)
      app.databases.use(.postgres(
        configuration: config
      ), as: .psql)
    } else {
      app.databases.use(
        .postgres(
          hostname: Environment.get("DATABASE_HOST") ??
            "localhost",
          port: databasePort,
          username: Environment.get("DATABASE_USERNAME") ??
            "vapor_username",
          password: Environment.get("DATABASE_PASSWORD") ??
            "vapor_password",
          database: Environment.get("DATABASE_NAME") ??
            databaseName),
        as: .psql)
    }

    app.views.use(.leaf)
    
    app.migrations.add(CreateClubNight())
    app.migrations.add(User.Migration())
    app.migrations.add(UserToken.Migration())
    app.migrations.add(ClubNightUpdateMigration())
    app.migrations.add(ClubNightUpdateCurrentGuestsMigration())
    
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()
    
    //register custom tags
    app.leaf.tags["QRTag"] = QRTag()
    // register routes
    try routes(app)
    
}

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
    
    
    
    if let databaseURL = Environment.get("DATABASE_URL") {
        var tlsConfig: TLSConfiguration = .makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

        var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
        postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    }else {
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }

    app.views.use(.leaf)
    
    app.migrations.add(CreateClubNight())
    app.migrations.add(User.Migration())
    app.migrations.add(ClubNightUpdateMigration())
    app.migrations.add(ClubNightUpdateCurrentGuestsMigration())
    app.migrations.add(CreateClubNightData())
    app.migrations.add(ClubNightDatabaseTimeStampMigration())
    
    app.logger.logLevel = .debug
    
    try await app.autoMigrate()
    
    app.leaf.tags["liveCapacity"] = CurrentCapacityTag()
    
    let counterSystem = CounterSystem(eventLoop: app.eventLoopGroup.next(), database: app.db)
    app.webSocket("session") { req, ws in
        counterSystem.connect(ws, req)
    }
    
    
    // register routes
    try routes(app, counterSystem: counterSystem)
    
}

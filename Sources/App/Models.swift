import Fluent
import Vapor
import FluentPostgresDriver
import Leaf

struct RoutesDescription: Encodable{
    var httpMethod: String
    var route: String
    var description: String
}

struct AllRoutes: Encodable{
    var routes: [RoutesDescription]
}

struct SystemPersonEntryView: Encodable{
    var firstname: String
    var lastname: String
    var id: String
    var ssn: String
    var gender: Int
    var email: String
    var color: String
    
    init(systemPerson: SystemPersonEntry, color: String){
        self.firstname = systemPerson.firstname
        self.lastname = systemPerson.lastname
        self.id = systemPerson.id!
        self.ssn = systemPerson.ssn
        self.gender = systemPerson.gender
        self.email = systemPerson.email
        self.color = color
    }
}

enum UserType: String, Codable{
    case Boss
    case Manager
    case Staff
}

final class UserAuth: Model, Content{
    static let schema: String = "serverexample_user_auth"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @OptionalField(key: "password")
    var password: String?
    
    @Enum(key: "user_type")
    var userType: UserType
    
    init(){
        
    }
    
    init(id: UUID? = nil, username: String, password: String? = nil, userType: UserType){
        self.id = id
        self.username = username
        if password != nil{
            self.password = password
        }
        else{
            let usernameData = Data(self.username.utf8)
            let usernameHashed = SHA256.hash(data: usernameData)
            self.password = usernameHashed.hex
        }
        self.password = password
        self.userType = userType
    }
}



final class SystemPersonEntry: Model, Content{
    static let schema: String = "serverexample_systemperson_entry"
    
    @ID(custom: "id", generatedBy: .random)
    var id: String?
    
    @Field(key: "ssn")
    var ssn: String
    
    @Field(key: "firstname")
    var firstname: String
    
    @Field(key: "lastname")
    var lastname: String
    
    @Field(key: "gender")
    var gender: Int

    @Field(key: "email")
    var email: String
    
    init(){
    }
    
    init(id: String? = nil, ssn: String, firstname: String, lastname: String, gender: Int, email: String){
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.gender = gender
        self.email = email
    }
}

func routes(_ app: Application) throws {
    try app.register(collection: UserAuthController())
    try app.register(collection: SystemPersonEntryController())
    app.get{ req -> EventLoopFuture<View> in
        return req.view.render("HomePage.html")
    }
}

public func configure(_ app: Application) throws {

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "Server_Example"
    ), as: .psql)

    app.migrations.add(UserAuthMigrations())
    app.migrations.add(SystemPersonEntryMigrations())

    app.views.use(.plaintext)
    app.routes.defaultMaxBodySize = "10mb"
    

    // register routes
    try routes(app)
}

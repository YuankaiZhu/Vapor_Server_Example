import Fluent
import Vapor

struct UserAuthMigrations: AsyncMigration{
    func prepare(on database: Database) async throws{
        
        let userTypeDBEnum = try await database.enum("user_type")
            .case("Boss")
            .case("Manager")
            .case("Staff")
            .create()
        
        try await database.schema("serverexample_user_auth")
            .id()
            .field("username", .string, .required)
            .field("password", .string)
            .field("user_type", userTypeDBEnum, .required)
            .unique(on: "username")
            .create()
        
        let AdminUser = UserAuth(id: UUID(), username: "123", password: "serverexample", userType: UserType.Boss)
        try await AdminUser.create(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("serverexample_user_auth").delete()
    }
}



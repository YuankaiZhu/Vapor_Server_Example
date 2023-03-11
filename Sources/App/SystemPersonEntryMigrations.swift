import Fluent
import FluentPostgresDriver
import Vapor

struct SystemPersonEntryMigrations: AsyncMigration{
    /*MARK: Note
     This function is never used since we cannot create
     primary keys of string type.
     The workaround this is to create a table manually
     with the appropriate types
     */
    func prepare(on database: Database) async throws {
        try await database.schema("serverexample_systemperson_entry")
            .field("id", .string, .identifier(auto: false))
            .field("ssn", .string, .required)
            .field("firstname", .string, .required)
            .field("lastname" ,.string, .required)
            .field("gender", .int, .required)
            .field("email", .string)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("serverexample_systemperson_entry").delete()
    }
}

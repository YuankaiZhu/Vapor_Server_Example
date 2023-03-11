import Fluent
import Vapor

struct SystemPersonEntryController: RouteCollection{
    func boot(routes: RoutesBuilder) throws {
        let systemPeople = routes.grouped("entries")
        systemPeople.get(use: index)
        systemPeople.group("create"){ systemPerson in
            systemPerson.post(use: create)
        }
        systemPeople.group("all"){systemPerson in
            systemPerson.get(use: getAllEntries)
        }
        systemPeople.group(":ssn"){systemPerson in
            systemPerson.get(use: getEntryById)
            systemPerson.put(use: updateEntryById)
            systemPerson.delete(use: deleteEntry)
        }
    }
    
    //MARK: Index -> Show all entries
    func index(req: Request) throws -> EventLoopFuture<View> {
        return SystemPersonEntry.query(on: req.db).all().flatMap{ allSystemPeople in
            var allPeople: [SystemPersonEntryView] = [SystemPersonEntryView]()
            for person in allSystemPeople{
                let idHashed = person.id!.hashValue
                let constant = idHashed & 0xFFFFFF
                let hexString = String(format: "%06x", constant)
                let color = hexString.suffix(6).uppercased()
                allPeople.append(SystemPersonEntryView(systemPerson: person, color: color))
            }
            
            return req.leaf.render("SystemPeopleIndex.leaf", ["systemPeople": allPeople])
        }
    }
    
    /*
     MARK: Create/Update a new entry
     */
    func create(req: Request) async throws -> HTTPStatus{
        let authHeader = req.headers.basicAuthorization
        let systemPerson = try req.content.decode(SystemPersonEntry.self)
        
        if authHeader == nil{
            return HTTPStatus(statusCode: 401, reasonPhrase: "No authorization details provided.")
        }

        if authHeader!.username != systemPerson.ssn{
            return HTTPStatus(statusCode: 401, reasonPhrase: "Unauthorized access, cannot modify another person's data")
        }
        let findUserInTable = try await UserAuth.query(on: req.db).filter(\.$username == authHeader!.username).all()
        
        if findUserInTable.count == 0{
            return HTTPStatus(statusCode: 401, reasonPhrase: "User with ssn \(systemPerson.ssn) doesn't exist.")
        }
        
        let userFound = findUserInTable.first!
        
        if userFound.username != authHeader!.username || userFound.password != authHeader!.password{
            return HTTPStatus(statusCode: 401, reasonPhrase: "Invalid credentials provided")
        }
        let values = try await SystemPersonEntry.query(on: req.db).filter(\.$ssn == systemPerson.ssn).all()
        
        if values.count == 0{
            systemPerson.id = UUID().uuidString
            try await systemPerson.create(on: req.db)
            return HTTPStatus(statusCode: 200, reasonPhrase: "Created a new SystemPerson")
        }
        else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Entry already exists")
        }
    }
    
    func getAllEntries(req: Request) async throws -> [SystemPersonEntry]{
        let authHeaders = req.headers.basicAuthorization
        
        if let authHeaders = authHeaders{
            
            //Checking if these credentials match with ones existing in the database
            guard (try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first()) != nil else{
                throw Abort(HTTPResponseStatus(statusCode: 401, reasonPhrase: "User does not exist"))
            }
            
            let allUsers = try await SystemPersonEntry.query(on: req.db).all()
            return allUsers
            
        }
        else{
            throw Abort(HTTPResponseStatus(statusCode: 401, reasonPhrase: "No credentials provided"))
        }
    }
    
    func deleteEntry(req: Request) async throws -> HTTPStatus{
        guard let authHeaders = req.headers.basicAuthorization else{
            return HTTPStatus(statusCode: 404, reasonPhrase: "No credentials Provided")
        }
        guard let ssn = req.parameters.get("ssn") else {
            return HTTPStatus(statusCode: 400, reasonPhrase: "Invalid ID provided")
        }
        if ssn != authHeaders.username{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Can only delete your own entry")
        }
        
        guard let authUserEntry = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else {
            return HTTPStatus(statusCode: 404, reasonPhrase: "No entry for these credentials exists")
        }
        
        guard let entry = try await SystemPersonEntry.query(on: req.db).filter(\.$ssn == authUserEntry.username).first() else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "ID doesn't exist")
        }
        try await entry.delete(on: req.db)
        return HTTPStatus(statusCode: 200)
    }
    
    func getEntryById(req: Request) async throws -> SystemPersonEntry{
        guard let authHeaders = req.headers.basicAuthorization else{
            throw Abort(HTTPResponseStatus(statusCode: 401, reasonPhrase: "No credentials Provided"))
        }
        guard let id = req.parameters.get("ssn") else {
            throw Abort(HTTPResponseStatus(statusCode: 400, reasonPhrase: "Invalid ssn provided"))
        }
        
        guard let _ = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else {
            throw Abort(HTTPResponseStatus(statusCode: 401, reasonPhrase: "No entry for these credentials exists"))
        }
        
        guard let entry = try await SystemPersonEntry.query(on: req.db).filter(\.$ssn == id).first() else{
            throw Abort(HTTPResponseStatus(statusCode: 400, reasonPhrase: "ssn doesn't exist"))
        }
        
        return entry
    }
    
    func updateEntryById(req: Request)async throws -> HTTPStatus{
        guard let authHeaders = req.headers.basicAuthorization else{
            return HTTPStatus(statusCode: 404, reasonPhrase: "No credentials Provided")
        }
        guard let ssn = req.parameters.get("ssn") else {
            return HTTPStatus(statusCode: 400, reasonPhrase: "Invalid ID provided")
        }
        if ssn != authHeaders.username{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Can only delete your own entry")
        }
        
        guard let authUserEntry = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else {
            return HTTPStatus(statusCode: 404, reasonPhrase: "No entry for these credentials exists")
        }
        
        guard let entry = try await SystemPersonEntry.query(on: req.db).filter(\.$ssn == authUserEntry.username).first() else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "ID doesn't exist")
        }
        
        let newDetails = try req.content.decode(SystemPersonEntry.self)
        
        entry.firstname  = newDetails.firstname
        entry.lastname   = newDetails.lastname
        entry.gender     = newDetails.gender
        entry.email      = newDetails.email
        try await entry.update(on: req.db)
        return HTTPStatus(statusCode: 200, reasonPhrase: "Updated existing entry for \(newDetails.ssn)")
        
    }
}



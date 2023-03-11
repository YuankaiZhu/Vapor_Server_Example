import Fluent
import Vapor

struct UserAuthController: RouteCollection{
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("user")
        users.patch(use: update)
        users.group("create"){ user in
            user.post(use: create)
        }
        users.group("all"){ user in
            user.get(use: index)
        }
        users.group(":username"){user in
            user.delete(use: delete)
        }
    }
    
    func index(req: Request) async throws -> [UserAuth]{
        let authHeaders = req.headers.basicAuthorization
        if let authHeaders = authHeaders {
            let currentUser = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first()
            if currentUser == nil{
                return []
            }
            if currentUser!.userType == UserType.Staff{
                return []
            }

            else if currentUser!.userType == UserType.Manager{
                var onlyStaff = try await UserAuth.query(on: req.db).filter(\.$userType == UserType.Staff).all()
                onlyStaff.append(currentUser!)
                return onlyStaff
            }
            else{
                let allUsers = try await UserAuth.query(on: req.db).all()
                return allUsers
            }
        }
        else{
            return []
        }
    }
    
    //MARK: Create -> Decode the data received from the index function
    func create(req: Request) async throws -> HTTPStatus{
        
        //User to create
        let user = try req.content.decode(UserAuth.self)
        
        //Checking for basic auth headers
        guard let authHeaders = req.headers.basicAuthorization else{
            return HTTPStatus(statusCode: 401, reasonPhrase: "No credentials provided")
        }
        
        //Making sure that authHeaders have a corresponding entry in the database
        guard let authUserEntry = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Invalid credentials provided")
        }
        
        if authUserEntry.userType == UserType.Staff{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Staff cannot modify user entries")
        }
        else if (user.userType == UserType.Boss || user.userType == UserType.Manager) && authUserEntry.userType == UserType.Manager{
            return HTTPStatus(statusCode: 400, reasonPhrase: "TA(s) cannot create Manager/Boss entries")
        }
        else{
            //Create a password if password is not supplied
            if user.password == nil{
                let usernameData = Data(user.username.utf8)
                let usernameHashed = SHA256.hash(data: usernameData)
                user.password = usernameHashed.hex
            }
            try await user.create(on: req.db)
            return HTTPStatus(statusCode: 201, reasonPhrase: "Entry created successfully")
        }
    }
    
    func delete(req: Request) async throws -> HTTPStatus{
        guard let username = req.parameters.get("username") else{
            return HTTPStatus(statusCode: 404, reasonPhrase: "Invalid username Provided to delete")
        }
        guard let entry = try await UserAuth.query(on: req.db).filter(\.$username == username).first() else{
            return HTTPStatus(statusCode: 404, reasonPhrase: "Entry for this username does not exist")
        }
        if entry.userType == UserType.Boss{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Cannot delete a boss's entry")
        }
        guard let authHeaders = req.headers.basicAuthorization else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "No authorization headers provided" )
        }
        guard let userAuth = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Invalid credentials provided")
        }
        
        if userAuth.userType == UserType.Staff{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Staff cannot modify user entries")
        }
        else if userAuth.userType == UserType.Manager && entry.userType == UserType.Manager && username != userAuth.username {
            return HTTPStatus(statusCode: 400, reasonPhrase: "TAS can only delete their or other staff's' entries")
        }
        else{
            try await entry.delete(on: req.db)
        }
        return HTTPStatus(statusCode: 200, reasonPhrase: "User Entry Deleted Successfully")
    }
    
/*
 User's password and role can be updated using the route /user/:username
 */
    func update(req: Request) async throws -> HTTPStatus{
        let userNewDetails = try req.content.decode(UserAuth.self)
        
        //Checking if entry of this username exists in database
        guard let userEntry = try await  UserAuth.query(on: req.db).filter(\.$username == userNewDetails.username).first() else{
            return HTTPStatus(statusCode: 401, reasonPhrase: "User not found")
        }
        
        //Auth details of person who is making the request
        guard let authHeaders = req.headers.basicAuthorization else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "No basic auth headers provided")
        }
        
        //Find user that is making the request in the database
        guard let authUserEntry = try await UserAuth.query(on: req.db).filter(\.$username == authHeaders.username).filter(\.$password == authHeaders.password).first() else{
            return HTTPStatus(statusCode: 400, reasonPhrase: "Person trying to make request could not be found")
        }
        
        if authUserEntry.userType == UserType.Staff{
            return HTTPStatus(statusCode: 404, reasonPhrase: "Staff's cannot update details")
        }
        else if authUserEntry.userType == UserType.Manager && (userEntry.userType == UserType.Manager && userEntry.username != authUserEntry.username){
                return HTTPStatus(statusCode: 401, reasonPhrase: "Can only change your details as a Manager")
        }
        else{
            userEntry.password = userNewDetails.password
            userEntry.userType = userNewDetails.userType
            try await userEntry.update(on: req.db)
            return HTTPStatus(statusCode: 200, reasonPhrase: "Details updated")
        }
    }
}

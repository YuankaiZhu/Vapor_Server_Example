# Vapor Server Example


* ### **UserAuth:**

    This is how the UserAuth Model is defined in the code. The UserAuth entries have a unique constraint on the username field.


    final class UserAuth: Model, Content{
        var id: UUID?
        var username: String
        var password: String?
        var userType: UserType
    }
* ### **SystemPersonEntry**:

    ```
    final class SystemPersonEntry: Model, Content{
        var id: String?
        var ssn: String
        var firstname: String
        var lastname: String
        var gender: String
        var email: String    
    }
    ```
## **Routes**:
All the following routes require a basicAuthorization HTTP header, where a valid username and password entry is required. 
***
+ `GET` /user/all:

    Returns a list of UserAuth entries, `[UserAuth]`.
    This entry allows an authorized Manager/Boss to access entries depending on the following rules:

    * Boss have access to all entries
    * Manager can access all staffs' entries along with their own
    * Staff don't have access to this route
***
+ `POST` /user/create:

    Since it is a route based on the POST HTTP Method, it requires JSON data conforming to the model as shown above. An example JSON query would be: 
    ```
        {
            "username": "myname",
            "password": "mypass",
            "userType": "Boss"
        }
    ```
    or you could just skip the password field and query something like:
    ```
        {
            "username": "hisname",
            "userType": "Staff" 
        }
    ```
***
+ `DELETE` /user/ssn:

    This route is used to delete any entry from the database. 

***

+ `GET` /entries/:

    This route is the route where all staff' information can be seen. 

***

+ `POST` /entries/create:

    This route allows a new SystemPersonEntry to be created and saved in the database. 
    A basic JSON query would look like: 
    
    ``` 
        {
            "firstname": "Yuankai",
            "lastname": "Zhu", 
            "ssn": "123",
            "gender": "Male",
            "email": "000@gamil.com"
        }
    ```
    The username and password should be a valid entry in the UserAuth Table. 
    

***

+ `GET` /entries/all:

    This route returns a `[SystemPersonEntry]`, so that all the entries can be accessed by anyone. 

***

+ `DELETE` /entries/ssn:

    This route is used to delete entries from the SystemPersonEntry Table.

***

+ `PUT` /entries/ssn:
  
    This route is used to update a particular entry with ssn.
    ```
    {
            "firstname": "Yuankai",
            "lastname": "Zhu", 
            "ssn": "123",
            "gender": "Male",
            "email": "000@gamil.com"
        }
    ```

+ `GET` /entries/ssn:
  
    This route is used to retrieve a particular entry with ssn.

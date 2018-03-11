//
//  StravaInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import CoreData

/**
 Interactor for accessing information from Strava's RESTful API
 
 - See:
    https://developers.strava.com/docs/reference/
 */
class StravaInteractor {
    
    enum StravaInteratorError: Error {
        case invalidURL
        case notAuthenticated
        case invalidCredentials
    }
    
    private enum RedirectURL: String {
        case dev = "localhost" // localhost is whitelisted, or so they claim
        case prod = "http://blockoftext.com/strava" // this doesn't exist yet but will if this ever gets deployed
    }
    
    private static let AUTH_LOGIN_PATH = "/oauth/authorize"
    private static let AUTH_EXCHANGE_PATH = "/oauth/token"
    private static let AUTH_HOST = "www.strava.com"
    private static let AUTH_SCHEME = "https"
    
    private static let AUTH_RESPONSE_TYPE = "code" // required
    private static let AUTH_SCOPE = "view_private" // comma delimited, could also have "write"
    
    private static let AUTH_HEADER_NAME = "Authorization"
    
    // TODO: clean up and refactor
    private static let API_BASE_PATH = "/api/v3/"
    
    private static let API_ACTIVITY_LIST_PATH = "athlete/activities"
    private static let API_ATHLETE_ZONES = "athlete/zones"
    private static let API_ACTIVITY_PATH = "activities/"
    private static let API_STREAM_PATH = "streams/"
    private static let API_ATHLETE_PATH = "athletes/"
    private static let API_ATHLETE_STATS = "/stats"
    
    /**
     Container for API errors and messages
     
     - See: `https://developers.strava.com/docs/reference/#api-models-Fault`
     
     Example:
     `{"message":"Authorization Error","errors":[{"resource":"Athlete","field":"access_token","code":"invalid"}]}`
     */
    class StravaFault: Decodable {
        let message: String
        let errors: [StravaError]
        
        var type : FaultType? {
            get {
                return FaultType(rawValue: message)
            }
        }
        
        enum FaultType: String {
            case authorization = "Authorization Error"
            case rateLimit = "Rate Limit Exceeded"
        }
        
        class StravaError: Decodable {
            let resource: String
            let field: String
            let code: String
        }
    }
    
    /**
     Creates a URLRequest with the correct path/parameters for accessing the oAuth login for Strava
     
     - Example:
     
         `https://www.strava.com/oauth/authorize?
         client_id=9
         &response_type=code
         &redirect_uri=http://testapp.com/token_exchange
         &scope=write
         &state=mystate
         &approval_prompt=force`
     
     - Throws: StravaInteratorError.invalidURL in case of invalid configuration
    */
    static func createAuthenticationURLRequest() throws -> URLRequest {
        
        // woop woop
        URLCache.shared.removeAllCachedResponses()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        var components = URLComponents(string: "")! // this shouldn't fail
        components.scheme = AUTH_SCHEME
        components.host = AUTH_HOST
        components.path = AUTH_LOGIN_PATH
        
        let credentials: APICredentials = ServiceLocator.shared.getService()
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "client_id", value: credentials.CLIENT_ID))
        queryItems.append(URLQueryItem(name: "response_type", value: AUTH_RESPONSE_TYPE))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: RedirectURL.prod.rawValue))
        queryItems.append(URLQueryItem(name: "scope", value: AUTH_SCOPE))

        components.queryItems = queryItems
        
        guard components.url != nil else {
            print("something messed up creating url")
            throw StravaInteratorError.invalidURL
        }

        return URLRequest(url: components.url!)
    }
    
    /**
     This will test for the redirect url (to signify the login was correct) but won't catch
     the initial load or a failed login
     
     - Parameter url: The url to test
     */
    static func isCallbackURL(_ url: URL) -> Bool {
        return url.absoluteString.contains(RedirectURL.prod.rawValue) &&
            !url.absoluteString.contains(AUTH_LOGIN_PATH) &&
            !url.absoluteString.contains("error=access_denied")
    }
    

    /**
     Once the redirect URL has been captured, the "code" parameter must be extracted and then be exchanged with Strava for a proper
     access token.
     
     - See: https://developers.strava.com/docs/authentication/
     
     - Parameter redirectURL: URL to extract "?code=<code>" from
     - Parameter done: callback
    */
    static func getAuthenitcationTokenFromCode(redirectURL: URL, done: @escaping (StravaToken) -> Void) {
        let redirectComponents = URLComponents(url: redirectURL, resolvingAgainstBaseURL: true)
        
        guard redirectComponents != nil, redirectComponents?.queryItems != nil else {
            print("malformed url: \(redirectURL.absoluteString)")
            return
        }
        
        // find ?code=<code>
        let token = redirectComponents!.queryItems!.first { queryItem in
            return queryItem.name == "code"
        }?.value
        
        guard token != nil else {
            fatalError("auth token not found")
        }
        
        // build token exchange request
        var exchangeComponents = URLComponents(string: "")! // this shouldn't fail
        exchangeComponents.scheme = AUTH_SCHEME
        exchangeComponents.host = AUTH_HOST
        exchangeComponents.path = AUTH_EXCHANGE_PATH
        
        let credentials: APICredentials = ServiceLocator.shared.getService()

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "client_id", value: credentials.CLIENT_ID))
        queryItems.append(URLQueryItem(name: "client_secret", value: credentials.CLIENT_SECRET))
        queryItems.append(URLQueryItem(name: "code", value: token!))

        exchangeComponents.queryItems = queryItems
        
        guard exchangeComponents.url != nil else {
            print("something messed up creating url")
            return
        }
        
        var request = URLRequest(url: exchangeComponents.url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            // TODO: HTTP Status code check, check for rate limit exceeded
            do {
                // Decode with StravaUser, which will create the Athlete managed object
                let decoder = CoreDataInteractor.JSONDecoderWithContext()
                let user = try decoder.decode(StravaUser.self, from: data)
                print("Logging in as: \(user.athlete.fullName)")
                
                // Save token, which has the access_token and a reference to the logged in Athlete
                let token = StravaToken(access_token: user.access_token, token_type: user.token_type, athlete_id: user.athlete.id)
                
                // callback
                done(token)
            } catch DecodingError.keyNotFound(let key, let context) {
                print("key not found: \(key); context: \(context.debugDescription)")
            } catch let err {
                print("an error ocurred: \(err.localizedDescription)")
            }
            // TODO: what happens in case of an error decoding the athlete?
        }
        task.resume()
    }
    
    /**
     Gets the most recent X activities (in summary form) from the Strava API for the logged in user
     
     - See: https://developers.strava.com/docs/reference/#api-Activities-getActivityById
     
     - Parameter count: # of activities to get, default 10. API rejects requests with count > 200
     - Parameter done: callback
    */
    static func getActivityList(_ count: Int = 10, _ done: @escaping ([StravaActivity]?, StravaFault?) -> Void)  throws {
        
        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path = API_BASE_PATH + API_ACTIVITY_LIST_PATH
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "per_page", value: "\(count)"))
        requestComponents.queryItems = queryItems

        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        try addAuthField(request: &request)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            callbackHandler(type: [StravaActivity].self, data: data, response: response, error: error, done: done)
        }
        task.resume()
    }
    
    /**
     Gets detailed activity info
    */
    static func getActivity(id: Int, done: @escaping (StravaActivity?, StravaFault?) -> Void) throws {
        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path = API_BASE_PATH + API_ACTIVITY_PATH + "/\(id)"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "include_all_efforts", value: "true"))
        requestComponents.queryItems = queryItems
        
        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        try addAuthField(request: &request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            callbackHandler(type: StravaActivity.self, data: data, response: response, error: error, done: done)
        }
        task.resume()
    }
    
    /**
     Gets a Stream associated with an Activity. By default the API will return 2, the relative distance and the requested stream.
     
     - See: https://developers.strava.com/docs/reference/#api-Streams
     
     - Parameter activity: Parent activity of the stream
     - Parameter type: Type of the stream to request.
     - Parameter resolution: The level of detail (sampling) in which this stream was returned
     - Parameter done: callback
     */
    static func getStream(activity: StravaActivity, type: StreamType, resolution: StreamResolution, done: @escaping ([StravaStream]?, StravaFault?) -> Void ) throws {

        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path =
            API_BASE_PATH + API_ACTIVITY_PATH + activity.id.description + "/" + API_STREAM_PATH + type.rawValue
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "resolution", value: resolution.rawValue))
        requestComponents.queryItems = queryItems
        
        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        try addAuthField(request: &request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            callbackHandler(type: [StravaStream].self, data: data, response: response, error: error, done: done)
        }
        task.resume()
    }
    
    /**
     Gets the athlete's heart rate zones (power zones are ignored. cyclists need not apply).
     Setting custom zones is a premium feature, but Strava 'guesses' for athletes that recored HR data. 
     
     - See: https://developers.strava.com/docs/reference/#api-Athletes-getLoggedInAthleteZones
 
     */
    static func getZones(_ done: @escaping ([String: StravaAthlete.Zones]?, StravaFault?) -> Void) throws {
        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path = API_BASE_PATH + API_ATHLETE_ZONES
        
        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        try addAuthField(request: &request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            callbackHandler(type: [String: StravaAthlete.Zones].self, data: data, response: response, error: error, done: done)
        }
        task.resume()
    }
    
    /**
 
     - See: https://developers.strava.com/docs/reference/#api-Athletes-getStats
    */
    static func getStats(id: Int, done: @escaping (StravaAthlete.Stats?, StravaFault?) -> Void) throws {
        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path = API_BASE_PATH + API_ATHLETE_PATH + id.description + API_ATHLETE_STATS
        
        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        try addAuthField(request: &request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            callbackHandler(type: StravaAthlete.Stats.self, data: data, response: response, error: error, done: done)
        }
        task.resume()
    }
    
    /**
     A generic handler for decoding API responses
     
     NOTE: Saves NSManagedObjectContext as a side effect
    */
    private static func callbackHandler <T: Decodable> (type: T.Type, data: Data?, response: URLResponse?, error: Error?, done: (T?, StravaFault?) -> Void) {
        // Save managed object context
        defer {
            let context: NSManagedObjectContext = ServiceLocator.shared.getService()
            try? context.save()
        }
        
        // check for network errors
        guard let response = response as? HTTPURLResponse, let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            done(nil, nil)
            return
        }
        
        // check for api errors
        guard response.statusCode == 200 else {
            do {
                let fault = try JSONDecoder().decode(StravaFault.self, from: data)
                done(nil, fault)
            } catch {
                print("an error ocurred: \(error) \n\(String(data: data, encoding: .utf8)!)")
            }
            return
        }
        
        // Decode
        do {
            let decoder = CoreDataInteractor.JSONDecoderWithContext()
            let entities = try decoder.decode(T.self, from: data)
            done(entities, nil)
        } catch {
            print("Error parsing \(String(describing: T.self)): \(error) \n\(String(data: data, encoding: .utf8)!)")
            done(nil, nil)
        }
    }
    
    /**
     Adds the correct information for an Authenticated request to the Strava API
     
     - See: https://developers.strava.com/docs/authentication/
     */
    private static func addAuthField(request: inout URLRequest) throws {
        // TODO: should this be passed in?
        guard let user = ServiceLocator.shared.tryGetService() as StravaToken? else {
            throw StravaInteratorError.notAuthenticated
        }
        
        request.addValue(user.token_type + " " + user.access_token, forHTTPHeaderField: AUTH_HEADER_NAME)
    }
}

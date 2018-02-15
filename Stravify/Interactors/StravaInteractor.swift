//
//  StravaInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

class StravaInteractor {
    
    enum StravaInteratorError: Error {
        case invalidURL
        case notAuthenticated
        case invalidCredentials
    }
    
    enum RedirectURL: String {
        case dev = "localhost" // localhost is whitelisted, or so they claim
        case prod = "http://blockoftext.com/strava" // this doesn't exist yet but will if this ever gets deployed
    }
    
    static let AUTH_LOGIN_PATH = "/oauth/authorize"
    static let AUTH_EXCHANGE_PATH = "/oauth/token"
    static let AUTH_HOST = "www.strava.com"
    static let AUTH_SCHEME = "https"
    
    static let AUTH_RESPONSE_TYPE = "code" // required
    static let AUTH_SCOPE = "view_private" // comma delimited, could also have "write"
    
    static let AUTH_HEADER_NAME = "Authorization"
    
    static let API_BASE_PATH = "/api/v3/"
    static let API_ACTIVITY_LIST_PATH = "athlete/activities"
    
    private static func loadCredentialsFromBundle() throws -> StravaCredentials {
        guard let credentialsPath = Bundle.init(for: self).url(forResource: "credentials", withExtension: "json") else {
            print("credentials not found")
            throw StravaInteratorError.invalidCredentials
        }
        
        let jsonData = try Data(contentsOf: credentialsPath)
        return try JSONDecoder().decode(StravaCredentials.self, from: jsonData)
    }
    
    /*
     Example:
         https://www.strava.com/oauth/authorize?
         client_id=9
         &response_type=code
         &redirect_uri=http://testapp.com/token_exchange
         &scope=write
         &state=mystate
         &approval_prompt=force
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
        
        let credentials = try loadCredentialsFromBundle()
        
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
    
    // this will catch the redirect load but not the accept_application request to strava or the inital load
    static func isCallbackURL(_ url: URL) -> Bool {
        return url.absoluteString.contains(RedirectURL.prod.rawValue) &&
            !url.absoluteString.contains(AUTH_LOGIN_PATH) &&
            !url.absoluteString.contains("error=access_denied")
    }
    
    // do code exchange for auth token and profile info
    // TODO: error handling
    static func getAuthenitcationTokenFromCode(redirectURL: URL, done: @escaping (StravaUser) -> Void) {
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
            print("auth token not found")
            return
        }
        
        // build token exchange request
        var exchangeComponents = URLComponents(string: "")! // this shouldn't fail
        exchangeComponents.scheme = AUTH_SCHEME
        exchangeComponents.host = AUTH_HOST
        exchangeComponents.path = AUTH_EXCHANGE_PATH
        
        let credentials = try! loadCredentialsFromBundle()
        
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
            
            // TODO: HTTP Status code check
            do {
                let user = try JSONDecoder().decode(StravaUser.self, from: data)
                done(user)
            } catch DecodingError.keyNotFound(let key, let context) {
                print("key not found: \(key); context: \(context.debugDescription)")
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("\(String(describing: json))")
            } catch let err {
                print("an error ocurred: \(err.localizedDescription)")
            }
            
        }
        task.resume()
    }
    
    // gets last X activities by logged in user
    static func getActivityList(_ done: @escaping ([Activity]) -> Void) throws {
        
        // TODO: should this be passed in?
        guard let user = ServiceLocator.shared.tryGetService() as StravaUser? else {
            throw StravaInteratorError.notAuthenticated
        }
        
        // build request
        var requestComponents = URLComponents(string: "")! // this shouldn't fail
        requestComponents.scheme = AUTH_SCHEME
        requestComponents.host = AUTH_HOST
        requestComponents.path = API_BASE_PATH + API_ACTIVITY_LIST_PATH
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "per_page", value: "10"))
        requestComponents.queryItems = queryItems

        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"
        request.addValue(user.token_type + " " + user.access_token, forHTTPHeaderField: AUTH_HEADER_NAME)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                done([])
                return
            }
            
            do {
                let activities = try JSONDecoder().decode([Activity].self, from: data)
                done(activities)
            } catch let err {
                print("an error ocurred: \(err)")
                done([])
            }
        }
        task.resume()
    }
}

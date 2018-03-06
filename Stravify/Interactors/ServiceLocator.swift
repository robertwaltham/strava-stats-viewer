//
//  ServiceLocator.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-03.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/**
 A basic implementation of a service locator in Swift.
 
 Each Type can only have one registered service. Service Type is inferred from the context.
 
 Services are basically a singleton, but can be overridden in a subclass to provide a testable interface
 
 TODO: Refactor tryGetService() to use error throwing
 
 Example:
 ```
 let loadedService: AServiceClass = ServiceLocator.shared.getService()
 let anotherLoadedService = ServiceLocator.shared.getService() as! AnotherServiceClass
 ```
 
 Registered Services
 
* APICredentials - stored strava/gmaps keys
* DispatchQueue - shared queue for callbacks
* [WeatherStation] - list loaded JSON filtered cached stations
* StravaToken - logged in user credentials
* NSPersistentContainer - Core data container
* NSManagedObjectContext - Core data object context
 
    basic service locator that looks up services by class
 */
class ServiceLocator {
    private var registry : [String: Any] = [:]
    
    static var shared : ServiceLocator = ServiceLocator()
    
    /**
     Registers a service to be kept in memory
    */
    func registerService<T>(service: T) {
        let key = "\(T.self)"
        registry[key] = service
    }
    
    /**
     Looks up a registered service, returns an Optional
    */
    func tryGetService<T>() -> T? {
        let key = "\(T.self)"
        return registry[key] as? T
    }
    
    /**
     Looks up a registered but throws a runtime error if it doesn't exist
    */
    func getService<T>() -> T {
        let key = "\(T.self)"
        return registry[key] as! T
    }
}

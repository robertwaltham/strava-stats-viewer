//
//  ServiceLocator.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-03.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/*
    basic service locator that looks up services by class
 */
class ServiceLocator {
    private var registry : [String: Any] = [:]
    
    static var shared : ServiceLocator = ServiceLocator()
    
    func registerService<T>(service: T) {
        let key = "\(T.self)"
        registry[key] = service
    }
    
    func tryGetService<T>() -> T? {
        let key = "\(T.self)"
        return registry[key] as? T
    }
    
    func getService<T>() -> T {
        let key = "\(T.self)"
        return registry[key] as! T
    }
}

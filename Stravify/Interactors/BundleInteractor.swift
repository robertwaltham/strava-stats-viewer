//
//  BundleInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/**
 Helper class to load resources from the main bundle
 */
class BundleInteractor {
    
    enum BundleInteratorError: Error {
        case invalidCredentials
        case csvStationNotFound
    }
    
    /**
     Loads API keys from bundle.
    */
    static func loadCredentialsFromBundle() throws -> APICredentials {
        guard let credentialsPath = Bundle.init(for: self).url(forResource: "credentials", withExtension: "json") else {
            print("credentials not found")
            throw BundleInteratorError.invalidCredentials
        }
        
        let jsonData = try Data(contentsOf: credentialsPath)
        return try JSONDecoder().decode(APICredentials.self, from: jsonData)
    }
    
    /**
     Loads raw weather station list from bundle. This data includes all public weather stations that have ever recored
     climate data in Canada.
    */
    static func readStationInventory() throws -> [WeatherStation] {
        guard let filePath = Bundle.main.path(forResource: "StationInventory", ofType: "json") else {
            print("No station csv found, wtf?")
            throw BundleInteratorError.csvStationNotFound
        }
        
        // load
        let fileURL = URL(fileURLWithPath: filePath)
        let csvData = try Data(contentsOf: fileURL)
        
        return try JSONDecoder().decode([WeatherStation].self, from: csvData)
    }
}

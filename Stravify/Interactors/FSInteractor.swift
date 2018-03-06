//
//  FSInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-04.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/**
 A basic file system interactor that can load and save `Codable` objects (including Arrays) 
 
 Objects are saved in path `~/<ObjectType>/<explicit id>.json`
 
 This is being phased out in favour of Core Data
 */
class FSInteractor {
    
    enum Errors: Error {
        case notFound
        case noDocDir
        case wrongType
        case creationFailed
    }
    
    /**
        Saves a codable object as JSON to `~/Documents/ObjectType/id.json`
     
     - Parameter object: Codable object to save
     - Parameter id: Explicit id representing the object uniquely
     
    */
    static func save<T : Codable>(_ object: T, id: String) throws {
        let fm = FileManager.default
        let documentDirectory = try docsDir()
        let objectDirectory = FSInteractor.dir(for: type(of: object))
        let dirpath = documentDirectory.appendingPathComponent(objectDirectory)
        if !fm.fileExists(atPath: dirpath.absoluteString) {
            try fm.createDirectory(at: dirpath, withIntermediateDirectories: true)
        }
        
        let objPath = dirpath.appendingPathComponent(id).appendingPathExtension("json")
        let jsonData = try JSONEncoder().encode(object)
        
        print("Writing \(id).json to ~/\(objectDirectory)/")
        
        try jsonData.write(to: objPath)
    }
    
    /**
     Loads a codable object from a JSON file from `~/Documents/ObjectType/id.json`
     
     - Parameter type: Object type
     - Parameter id: Explicit id that uniquely represents the object to load
    */
    static func load<T : Codable>(type: T.Type, id: String) throws -> T {
        let documentDirectory = try docsDir()
        let objectDirectory = FSInteractor.dir(for: type)
        let dirpath = documentDirectory.appendingPathComponent(objectDirectory)
        let objPath = dirpath.appendingPathComponent(id).appendingPathExtension("json")

        print("Reading \(id).json from ~/\(objectDirectory)/")
        
        let jsonData = try Data(contentsOf: objPath)
        
        return try JSONDecoder().decode(type, from: jsonData)
    }
    
    /**
     List all IDs that exist in `~/Documents/ObjectType/`
     
     - Parameter type: Object type
    */
    static func list<T: Codable>(type: T.Type) throws -> [String] {
        let documentDirectory = try docsDir()
        let objectDirectory = FSInteractor.dir(for: type)
        let dirpath = documentDirectory.appendingPathComponent(objectDirectory)
        
        print("Listing IDs from ~/\(objectDirectory)")

        return try FileManager.default.contentsOfDirectory(at: dirpath, includingPropertiesForKeys: []).map { url in
            return url.deletingPathExtension().lastPathComponent
        }
    }
    
    /**
     Base path for saving objects. Defaults to root document directory but can be overriden for testing.
    */
    static private func docsDir() throws -> URL {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("document url not found?")
            throw FSInteractor.Errors.noDocDir
        }
        return documentDirectory
    }
    
    /**
     Sanitizes type name so it can be used as a directory
     
     ex: `Array<WeatherStation> -> ArrayWeatherStation`
    */
    private static func dir(for type: Any) -> String {
        return String(describing: type)
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "<", with: "")
    }
}

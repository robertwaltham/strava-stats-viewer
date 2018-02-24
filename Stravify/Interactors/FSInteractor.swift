//
//  FSInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-04.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation


class FSInteractor {
    
    enum Errors: Error {
        case notFound
        case noDocDir
        case wrongType
        case creationFailed
    }
    
    // Saves a codable object as JSON to ~/Documents/ObjectType/id.json
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
    
    // Loads a codable object from a JSON file in ~/Documents/ObjectType/id.json
    static func load<T : Codable>(type: T.Type, id: String) throws -> T {
        let documentDirectory = try docsDir()
        let objectDirectory = FSInteractor.dir(for: type)
        let dirpath = documentDirectory.appendingPathComponent(objectDirectory)
        let objPath = dirpath.appendingPathComponent(id).appendingPathExtension("json")

        print("Reading \(id).json from ~/\(objectDirectory)/")
        
        let jsonData = try Data(contentsOf: objPath)
        
        return try JSONDecoder().decode(type, from: jsonData)
    }
    
    // List all IDs in ~/Documents/ObjectType/
    static func list<T: Codable>(type: T.Type) throws -> [String] {
        let documentDirectory = try docsDir()
        let objectDirectory = FSInteractor.dir(for: type)
        let dirpath = documentDirectory.appendingPathComponent(objectDirectory)
        
        print("Listing IDs from ~/\(objectDirectory)")

        return try FileManager.default.contentsOfDirectory(at: dirpath, includingPropertiesForKeys: []).map { url in
            return url.deletingPathExtension().lastPathComponent
        }
    }
    
    // grabs documents dir url 
    static private func docsDir() throws -> URL {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("document url not found?")
            throw FSInteractor.Errors.noDocDir
        }
        return documentDirectory
    }
    
    // ex: Array<WeatherStation> -> ArrayWeatherStation
    private static func dir(for type: Any) -> String {
        return String(describing: type)
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "<", with: "")
    }
}

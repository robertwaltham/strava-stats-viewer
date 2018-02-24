//
//  WeatherInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-23.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//
//  ftp://ftp.tor.ec.gc.ca/Pub/Get_More_Data_Plus_de_donnees/

import UIKit

class WeatherInteractor {
    
    enum WeatherInteractorError: Error{
        case csvStationNotFound
    }

    static func readStationInventory() throws -> [WeatherStation] {
        guard let filePath = Bundle.main.path(forResource: "StationInventory", ofType: "json") else {
            print("No station csv found, wtf?")
            throw WeatherInteractorError.csvStationNotFound
        }
        
        // load
        let fileURL = URL(fileURLWithPath: filePath)
        let csvData = try Data(contentsOf: fileURL)
      
        return try JSONDecoder().decode([WeatherStation].self, from: csvData)
    }
    
    static func filterStationInventory(stations: [WeatherStation]) -> [WeatherStation] {
        let minYear = 2015 // TODO: formalize this constant
        return stations.filter { station in
            return station.LastYear > minYear
        }
    }
}

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
        case stationsNotLoaded
    }
    
    enum WeatherDataType: String {
        case hourly = "1"
        case daily = "2"
        case monthly = "3"
    }

    // loads all stations from bundle file
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
    
    // filters bundle stations to stations active 2015-present
    static func filterStationInventory(stations: [WeatherStation]) -> [WeatherStation] {
        let minYear = 2015 // TODO: formalize this constant
        return stations.filter { station in
            return station.LastYear > minYear
        }
    }
    
    // returns the closest weather station that has a daily record for the activity start date
    static func weatherStation(activity: Activity) throws -> WeatherStation {
        guard let stations: [WeatherStation] = ServiceLocator.shared.tryGetService() else {
            print("no stations loaded")
            throw WeatherInteractorError.stationsNotLoaded
        }
        
        let activityLocation = CLLocation(latitude: activity.startLocation.latitude, longitude: activity.startLocation.longitude)
        let sortedStation = stations.sorted { a, b in
            return a.location.distance(from: activityLocation) < b.location.distance(from: activityLocation)
        }
        
        let activityYear = Calendar.current.component(.year, from: activity.startDate)
        let first = sortedStation.first { station in
            guard let hourlyFirst = station.HLYFirstYear, let hourlyLast = station.HLYLastYear else {
                return false
            }
            return hourlyFirst <= activityYear && hourlyLast >= activityYear
        }
        
        guard first != nil else {
            throw WeatherInteractorError.stationsNotLoaded
        }
        
        return first!
    }
    
    // see ftp://ftp.tor.ec.gc.ca/Pub/Get_More_Data_Plus_de_donnees/Readme.txt
    //http://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=1706&Year=${year}&Month=${month}&Day=14&timeframe=1&submit= Download+Data
    static func weather(activity: Activity, done: @escaping (HourlyWeather?) -> Void) throws {
        let station = try WeatherInteractor.weatherStation(activity: activity)
        
        let date = activity.startDate
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)

        // build request
        var requestComponents = URLComponents(string: "")!
        requestComponents.scheme = "http"
        requestComponents.host = "climate.weather.gc.ca"
        requestComponents.path = "/climate_data/bulk_data_e.html"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "format", value: "csv"))
        queryItems.append(URLQueryItem(name: "stationID", value: station.StationID.description))
        queryItems.append(URLQueryItem(name: "Year", value: year.description))
        queryItems.append(URLQueryItem(name: "Month", value: month.description))
        queryItems.append(URLQueryItem(name: "Day", value: day.description)) // apparently this doesn't do anything??
        queryItems.append(URLQueryItem(name: "timeframe", value: WeatherDataType.hourly.rawValue))
        queryItems.append(URLQueryItem(name: "submit", value: "Download+Data"))

        requestComponents.queryItems = queryItems
        
        var request = URLRequest(url: requestComponents.url!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            guard let parsedString = String(data: data, encoding: .utf8) else {
                print("no string data found for weather request")
                return
            }
            let weatherRecords = parseWeather(string: parsedString, stationID: station.StationID)
            
            let matched = weatherRecords.first { record in
                let cal = Calendar.current
                return cal.component(.hour, from: activity.startDate) == cal.component(.hour, from: record.date)
            }
            done(matched) 
        }
        task.resume()
    }
    
    static private func parseWeather(string: String, stationID: Int) -> [HourlyWeather] {
        var result: [HourlyWeather] = []
        let weatherRows = string.split(separator: "\n").suffix(from: 17) // 17 lines of information
        for substring in weatherRows {
            let elements = substring.split(separator: ",").map { split in
                return String(split).replacingOccurrences(of: "\"", with: "")
            }
        
            // some rows will not have all the data
            guard elements.count == HourlyWeatherCSVKeys.weather.rawValue + 1 else {
                continue
            }
            
            let weather = HourlyWeather(csvRow: elements, stationID: stationID)
            result.append(weather)
        }
        return result
    }
}

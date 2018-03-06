//
//  WeatherInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-23.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit

/**
 An interactor that interfaces with `climate.weather.gc.ca` to download bulk historical weather data
 
 - See:
  ftp://ftp.tor.ec.gc.ca/Pub/Get_More_Data_Plus_de_donnees/
 */
class WeatherInteractor {
    
    enum WeatherInteractorError: Error{
        case stationsNotLoaded
    }
    
    enum WeatherDataType: String {
        case hourly = "1"
        case daily = "2"
        case monthly = "3"
    }
    
    /**
     Filters list of weather stations and keeps only those that have been active for a relevant time
     
     For now this will be:
        * stations active 2015-present
    */
    static func filterStationInventory(stations: [WeatherStation]) -> [WeatherStation] {
        let minYear = 2015 // TODO: formalize this constant
        return stations.filter { station in
            return station.LastYear > minYear
        }
    }
    
    /**
     Look up the closest weather station for a given activity.
     
     Assumes the activity has GPS data.
     
     Sorts all loaded weather stations by distance from the activity start location, and then filters for the first
     station that has been active for hourly data.
     
     TODO: Many weather stations don't record condition data for historical weather; just temperature. In the case where the
     closest station does not have conditions data use only the temperature from that station and find another nearby station that
     has conditions data. This will probably require external data on the stations for which ones have condition data.
    
    */
    static func weatherStation(activity: StravaActivity) throws -> WeatherStation {
        guard let stations: [WeatherStation] = ServiceLocator.shared.tryGetService() else {
            print("no stations loaded")
            throw WeatherInteractorError.stationsNotLoaded
        }
        
        // Sort by distance from the activity start
        let activityLocation = CLLocation(latitude: activity.startLocation.latitude, longitude: activity.startLocation.longitude)
        let sortedStation = stations.sorted { a, b in
            return a.location.distance(from: activityLocation) < b.location.distance(from: activityLocation)
        }
        
        // first station that had hourly stats in the correct year
        let activityYear = Calendar.current.component(.year, from: activity.startDate)
        let first = sortedStation.first { station in
            guard let hourlyFirst = station.HLYFirstYear, let hourlyLast = station.HLYLastYear else {
                return false
            }
            
            // uncomment this to guarantee a vancouver weather station that has conditions listed
            // return station.TCID == "YVR"
            
            return hourlyFirst <= activityYear && hourlyLast >= activityYear
        }
        
        guard first != nil else {
            throw WeatherInteractorError.stationsNotLoaded
        }
        
        return first!
    }
    
    // File system ID for saving hourly data. Format: STNID_YEAR_MONTH_DAY_HOUR
    private static func idForSaving(date: Date, station: WeatherStation) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        return "\(station.StationID)_\(components.year!)_\(components.month!)_\(components.day!)_\(components.hour!)"
    }
    
    
    /**
     Helper function to match station record date with activity date
     
     The dates are a match if the day and hour are the same. It is assumed the dates have the same month and year.
    */
    private static func match(a: Date, b: Date) -> Bool {
        let cal = Calendar.current
        let compA = cal.dateComponents([.day, .hour], from: a)
        let compB = cal.dateComponents([.day, .hour], from: b)
        
        return compA.day == compB.day && compA.hour == compB.hour
    }
    
    /**
     Loads the hourly weather for an activity.
     
     First checks filesystem cache then loads from the weather API.
     
     - see `ftp://ftp.tor.ec.gc.ca/Pub/Get_More_Data_Plus_de_donnees/Readme.txt`
    */
    static func weather(activity: StravaActivity, done: @escaping (HourlyWeather?) -> Void) throws {
        let station = try WeatherInteractor.weatherStation(activity: activity)
        let key = idForSaving(date: activity.startDate, station: station)

        // Weather records are cached by station and date
        let cachedWeather = try? FSInteractor.load(type: HourlyWeather.self, id: key)
        
        if let cachedWeather = cachedWeather {
            done(cachedWeather)
        } else {
            try loadWeather(activity: activity, station: station) { loadedWeather in
                
                let queue: DispatchQueue = ServiceLocator.shared.getService()
             
                // save each individually
                for weather in loadedWeather {
                    queue.async {
                         try? FSInteractor.save(weather, id: idForSaving(date: weather.date, station: station))
                    }
                }
                
                // match
                let matched = loadedWeather.first { record in
                    return match(a: activity.startDate, b: record.date)
                }
                
                done(matched)
            }
        }
    }
    
    /**
     Loads hourly weather for the given `StravaActivity` and `WeatherStation` from the weather API
     
     The API is pretty simple and will always give you the climate records for the entire month in CSV form,
     even if you only asked for a single day.
     
     URL for downloading:
     
     `http://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=1706&Year=${year}&Month=${month}&Day=14&timeframe=1&submit= Download+Data`
    */
    private static func loadWeather(activity: StravaActivity, station: WeatherStation, done: @escaping ([HourlyWeather]) -> Void) throws {
        
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
            
            // Parse returned Weather records
            let weatherRecords = parseWeather(string: parsedString, stationID: station.StationID)
            
            done(weatherRecords)
        }
        task.resume()
    }
    
    /**
     Parse returned CSV rows from the API
     
     Note:
        The standard response has 17 lines of informational content before the data begins
        Dates and times in the future for the date range still will have a row but no data
     
     - Parameter string: String representing a CSV file
     - Parameter stationID: Weather needs a reference to it's parent station
    */
    static private func parseWeather(string: String, stationID: Int) -> [HourlyWeather] {
        var result: [HourlyWeather] = []
        let weatherRows = string.split(separator: "\n").suffix(from: 17) // 17 lines of information
        for substring in weatherRows {
            let elements = substring.split(separator: ",").map { split in
                return String(split).replacingOccurrences(of: "\"", with: "")
            }
        
            // some rows will have a date but no data (usually because it's in the future)
            guard elements.count == HourlyWeatherCSVKeys.weather.rawValue + 1 else {
                continue
            }
            
            let weather = HourlyWeather(csvRow: elements, stationID: stationID)
            result.append(weather)
        }
        return result
    }
}

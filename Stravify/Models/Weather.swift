//
//  Weather.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-23.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/*
 "All times are specified in Local Standard Time (LST). Add 1 hour to adjust for Daylight Saving Time where and when it is observed."

 "Legend"
 "E","Estimated"
 "M","Missing"
 "NA","Not Available"
 "‡","Partner data that is not subject to review by the National Climate Archives"
 */

enum HourlyWeatherFlag: String, Codable {
    case estimated = "E"
    case missing = "M"
    case notAvailable = "NA"
    case parterData = "‡"
}

/*
 "Date/Time","Year","Month","Day","Time","Data Quality","Temp (°C)","Temp Flag","Dew Point Temp (°C)","Dew Point Temp Flag","Rel Hum (%)","Rel Hum Flag","Wind Dir (10s deg)","Wind Dir Flag","Wind Spd (km/h)","Wind Spd Flag","Visibility (km)","Visibility Flag","Stn Press (kPa)","Stn Press Flag","Hmdx","Hmdx Flag","Wind Chill","Wind Chill Flag","Weather"
 */

enum HourlyWeatherCSVKeys: Int, RawRepresentable {
    case dateTime = 0
    case year
    case month
    case day
    case time
    case dataQuality
    case temp
    case tempFlag
    case dewPoint
    case dewPointFlag
    case relHum
    case relHumFlag
    case windDir
    case windDirFlag
    case windSpeed
    case windSpeedFlag
    case visibility
    case visibilityFlag
    case pressure
    case pressureFlag
    case humidity
    case humidityFlag
    case windChill
    case windChillFlag
    case weather
}

struct HourlyWeather : Codable {
    let stationID: Int // weather station id
    let date: Date
    let dataQuality: String
    let temp: Double // °C
    let tempFlag: HourlyWeatherFlag
    let dewPointTemp: Double // °C
    let dewPointTempFlag: HourlyWeatherFlag
    let relHum: Double // %
    let relHumFlag: HourlyWeatherFlag
    let windDir: Double // 10s deg
    let windDirFlag: HourlyWeatherFlag
    let windSpd: Double // km/h
    let windSpdFlag: HourlyWeatherFlag
    let visibility: Double // km
    let visibilityFlag: HourlyWeatherFlag
    let stnPress: Double
    let stnPressFlag: HourlyWeatherFlag
    let hmdx: Double
    let hmdxFlag: HourlyWeatherFlag
    let windChill: Double
    let windChillFlag: HourlyWeatherFlag
    let weather: String
    
    init(csvRow: [String], stationID: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        self.stationID = stationID
        date = dateFormatter.date(from: csvRow[HourlyWeatherCSVKeys.dateTime.rawValue]) ?? Date()
        
        dataQuality = csvRow[HourlyWeatherCSVKeys.dataQuality.rawValue]
        
        temp = Double(csvRow[HourlyWeatherCSVKeys.temp.rawValue]) ?? 0
        tempFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.tempFlag.rawValue]) ?? .missing
        
        dewPointTemp = Double(csvRow[HourlyWeatherCSVKeys.dewPoint.rawValue]) ?? 0
        dewPointTempFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.dewPointFlag.rawValue]) ?? .missing
        
        relHum = Double(csvRow[HourlyWeatherCSVKeys.relHum.rawValue]) ?? 0
        relHumFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.relHumFlag.rawValue]) ?? .missing
        
        windDir = Double(csvRow[HourlyWeatherCSVKeys.windDir.rawValue]) ?? 0
        windDirFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.windDirFlag.rawValue]) ?? .missing
        
        windSpd = Double(csvRow[HourlyWeatherCSVKeys.windSpeed.rawValue]) ?? 0
        windSpdFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.windSpeedFlag.rawValue]) ?? .missing
        
        visibility = Double(csvRow[HourlyWeatherCSVKeys.visibility.rawValue]) ?? 0
        visibilityFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.visibilityFlag.rawValue]) ?? .missing
        
        stnPress = Double(csvRow[HourlyWeatherCSVKeys.pressure.rawValue]) ?? 0
        stnPressFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.pressureFlag.rawValue]) ?? .missing
        
        hmdx = Double(csvRow[HourlyWeatherCSVKeys.humidity.rawValue]) ?? 0
        hmdxFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.humidityFlag.rawValue]) ?? .missing
        
        windChill = Double(csvRow[HourlyWeatherCSVKeys.windChill.rawValue]) ?? 0
        windChillFlag = HourlyWeatherFlag(rawValue: csvRow[HourlyWeatherCSVKeys.windChillFlag.rawValue]) ?? .missing
        
        weather = csvRow[HourlyWeatherCSVKeys.weather.rawValue]
    }
}



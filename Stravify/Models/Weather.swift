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

enum HourlyWeatherFlag: String {
    case estimated = "E"
    case missing = "M"
    case notAvailable = "NA"
    case parterData = "‡"
}

struct HourlyWeather {
    let Date: String
    let Year: String
    let Month: String
    let Day: String
    let Time: String
    let DataQuality: String
    let Temp: Double // °C
    let TempFlag: String
    let DewPointTemp: Double // °C
    let DewPointTempFlag: String
    let RelHum: Double // %
    let RelHumFlag: String
    let WindDir: Double // 10s deg
    let WindDirFlag: String
    let WindSpd: Double // km/h
    let WindSpdFlag: String
    let Visibility: Double // km
    let VisibilityFlag: String
    let StnPress: Double
    let StnPressFlag: String
    let Hmdx: Double
    let HmdxFlag: String
    let WindChill: Double
    let WindChillFlag: String
    let Weather: String
}



//
//  WeatherStation.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-23.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

//"Name","Province","Climate ID","Station ID","WMO ID","TC ID","Latitude (Decimal Degrees)","Longitude (Decimal Degrees)","Latitude","Longitude","Elevation (m)","First Year","Last Year","HLY First Year","HLY Last Year","DLY First Year","DLY Last Year","MLY First Year","MLY Last Year"
struct WeatherStation : Codable {
    let Name: String
    let Province: String
    let ClimateID: String
    let StationID: Int
    let WMOID: Int?
    let TCID: String
    let LatitudeDegrees: Double
    let LongitudeDegrees: Double
    let Latitude: Int
    let Longitude: Int
    let Elevation: Double?
    let FirstYear: Int
    let LastYear: Int
    let HLYFirstYear: Int?
    let HLYLastYear: Int?
    let DLYFirstYear: Int?
    let DLYLastYear: Int?
    let MLYFirstYear: Int?
    let MLYLastYear: Int?
}

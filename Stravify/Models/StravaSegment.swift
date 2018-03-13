//
//  StravaSegment.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-12.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/*
 {
     "id": 2309502,
     "resource_state": 2,
     "name": "Lower Lonsdale pier",
     "activity_type": "Run",
     "distance": 457.67,
     "average_grade": -0.1,
     "maximum_grade": 11.6,
     "elevation_high": 6.7,
     "elevation_low": 0.0,
     "start_latlng": [
         49.309244516666666,
         -123.07896191666666
     ],
     "end_latlng": [
         49.30933443333333,
         -123.07922150000002
     ],
     "start_latitude": 49.309244516666666,
     "start_longitude": -123.07896191666666,
     "end_latitude": 49.30933443333333,
     "end_longitude": -123.07922150000002,
     "climb_category": 0,
     "city": "North Vancouver",
     "state": "BC",
     "country": "Canada",
     "private": false,
     "hazardous": false,
     "starred": false
 },
 */

/**
 - See: https://developers.strava.com/docs/reference/#api-models-SummarySegment
 */
class StravaSegment: Codable {
    let id: Int
    let resource_state: Int
    let name: String
    let activity_type: String
    let distance: Double
    let average_grade: Double
    let maximum_grade: Double
    let elevation_high: Double
    let elevation_low: Double
    let start_latlng: [Double]
    let end_latlng: [Double]
    let start_latitude: Double
    let start_longitude: Double
    let end_latitude: Double
    let end_longitude: Double
    let climb_category: Int
    let city: String
    let state: String
    let country: String
    //let private: Bool 
    let hazardous: Bool
    let starred: Bool
    
}

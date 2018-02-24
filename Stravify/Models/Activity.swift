//
//  Activity.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-05.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps

/*
 
 {
     "id": 1392140243,
     "resource_state": 2,
     "external_id": "garmin_push_2478798425",
     "upload_id": 1502248877,
     "athlete": {
         "id": 8241500,
         "resource_state": 1
     },
     "name": "Superb Owl Sun Day - no owls, no sun, just some eagles",
     "distance": 10021.9,
     "moving_time": 3598,
     "elapsed_time": 3904,
     "total_elevation_gain": 54.0,
     "type": "Run",
     "start_date": "2018-02-04T20:39:08Z",
     "start_date_local": "2018-02-04T12:39:08Z",
     "timezone": "(GMT-08:00) America/Vancouver",
     "utc_offset": -28800.0,
     "start_latlng": [
         49.313122,
         -123.073568
     ],
     "end_latlng": [
         49.313825,
         -123.078022
     ],
     "location_city": "North Vancouver",
     "location_state": "British Columbia",
     "location_country": "Canada",
     "start_latitude": 49.313122,
     "start_longitude": -123.073568,
     "achievement_count": 0,
     "kudos_count": 14,
     "comment_count": 0,
     "athlete_count": 1,
     "photo_count": 0,
     "map": {
         "id": "a1392140243",
         "summary_polyline": "_n~kHxxdnVoEbNrCfDoa@~qAT|HdZHCpEjFXNzIgBpj@_RCyC|DqBF|BbTcBv\\p@dGs@bm@t@hJoDzUlD{Tc@i`AtAq^gCeTnCQfCiDzQEjB}k@MgHyEOi@oE}YU[uIt_@miA",
         "resource_state": 2
     },
     "trainer": false,
     "commute": false,
     "manual": false,
     "private": false,
     "flagged": false,
     "gear_id": "g2787060",
     "from_accepted_tag": false,
     "average_speed": 2.785,
     "max_speed": 4.0,
     "average_cadence": 85.7,
     "average_temp": 20.0,
     "has_heartrate": true,
     "average_heartrate": 155.0,
     "max_heartrate": 183.0,
     "elev_high": 52.6,
     "elev_low": 6.0,
     "pr_count": 0,
     "total_photo_count": 0,
     "has_kudoed": false,
     "workout_type": 0
 }
 
 */

struct Activity: Codable, CustomDebugStringConvertible {
    let id: Int
    let resource_state: Int
    let external_id: String?
    let upload_id: Int?
    let athlete: AthleteStub
    let name: String
    let distance: Float
    let moving_time: Int
    let elapsed_time: Int
    let total_elevation_gain: Float
    let type: String
    let start_date: String
    let start_date_local: String
    
    var startDate: Date {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter.date(from: start_date)!
        }
    }
    
    let timezone: String
    let utc_offset: Float
    
    let start_latlng: [Float]?
    var startLocation: CLLocationCoordinate2D {
        get {
            if start_latlng == nil {
                return CLLocationCoordinate2D()
            }
            return CLLocationCoordinate2DMake(CLLocationDegrees(start_latlng![0]), CLLocationDegrees(start_latlng![1]))
        }
    }
    
    let end_latlng: [Float]?
    var endLocation: CLLocationCoordinate2D {
        get {
            if end_latlng == nil {
                return CLLocationCoordinate2D()
            }
            return CLLocationCoordinate2DMake(CLLocationDegrees(end_latlng![0]), CLLocationDegrees(end_latlng![1]))
        }
    }
    
    let location_city: String?
    let location_state: String?
    let location_country: String?
    var locationString: String {
        get {
            let city = location_city ?? ""
            let state = location_state ?? ""
            let country = location_country ?? ""
            return (city + " " + state + " " + country).trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }
    
    let start_latitude: Float?
    let start_longitude: Float?
    let achievement_count: Int
    let kudos_count: Int
    let comment_count: Int
    let athlete_count: Int
    let photo_count: Int
    let map: Map
    let trainer: Bool
    let commute: Bool
    let manual: Bool
    let flagged: Bool
    let gear_id: String?
    let from_accepted_tag: Bool?
    let average_speed: Float?
    let max_speed: Float?
    let average_cadence: Float?
    let average_temp: Float?
    let has_heartrate: Bool
    let average_heartrate: Float?
    let max_heartrate: Float?
    let elev_high: Float?
    let elev_low: Float?
    let pr_count: Int
    let total_photo_count: Int
    let has_kudoed: Bool
    let workout_type: Int?
    
    var debugDescription: String {
        return "<Activity id:\(id) name:\(name) >"
    }
}

struct Map: Codable {
    let id: String
    let summary_polyline: String?
    let resource_state: Int
    
    var path: GMSPath {
        get {
            if summary_polyline == nil {
                return GMSPath()
            }
            return GMSPath(fromEncodedPath: summary_polyline!)!
        }
    }
}

struct AthleteStub: Codable {
    let id: Int
    let resource_state: Int
}

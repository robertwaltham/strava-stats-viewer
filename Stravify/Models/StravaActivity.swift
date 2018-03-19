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
import CoreData

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

class StravaActivity: NSManagedObject, Decodable {
    
    // Variables provided by SummaryActivity
    // See: https://developers.strava.com/docs/reference/#api-models-SummaryActivity
    
    @NSManaged var id: Int
    @NSManaged var athlete_id: Int
    @NSManaged var resource_state: Int
    @NSManaged var external_id: String?
    @NSManaged var upload_id: Int
    @NSManaged var name: String
    @NSManaged var distance: Float
    @NSManaged var moving_time: Int
    @NSManaged var elapsed_time: Int
    @NSManaged var total_elevation_gain: Float
    @NSManaged var type: String
    @NSManaged var start_date: String
    @NSManaged var start_date_local: String
    @NSManaged var timezone: String
    @NSManaged var utc_offset: Float
    var start_latlng: [Float]? // TODO: Decoding start/end
    var end_latlng: [Float]?
    @NSManaged var location_city: String?
    @NSManaged var location_state: String?
    @NSManaged var location_country: String?
    @NSManaged var start_latitude: Float
    @NSManaged var start_longitude: Float
    @NSManaged var achievement_count: Int
    @NSManaged var kudos_count: Int
    @NSManaged var comment_count: Int
    @NSManaged var athlete_count: Int
    @NSManaged var photo_count: Int
    @NSManaged var trainer: Bool
    @NSManaged var commute: Bool
    @NSManaged var manual: Bool
    @NSManaged var flagged: Bool
    @NSManaged var gear_id: String?
    @NSManaged var from_accepted_tag: Bool
    @NSManaged var average_speed: Float
    @NSManaged var max_speed: Float
    @NSManaged var average_cadence: Float
    @NSManaged var average_temp: Float
    @NSManaged var has_heartrate: Bool
    @NSManaged var average_heartrate: Float
    @NSManaged var max_heartrate: Float
    @NSManaged var elev_high: Float
    @NSManaged var elev_low: Float
    @NSManaged var pr_count: Int
    @NSManaged var total_photo_count: Int
    @NSManaged var has_kudoed: Bool
    @NSManaged var workout_type: Int
    @NSManaged var summary_polyline: String?
    
    // Variables provided as part of DetailedActivity
    // See: https://developers.strava.com/docs/reference/#api-models-DetailedActivity
    
    
    // Other variables loaded via API 
    @NSManaged var streams: Set<StravaStream>?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case map = "map"
        case athlete = "athlete"
        case resource_state = "resource_state"
        case external_id = "external_id"
        case upload_id = "upload_id"
        case name = "name"
        case distance = "distance"
        case moving_time = "moving_time"
        case elapsed_time = "elapsed_time"
        case total_elevation_gain = "total_elevation_gain"
        case type = "type"
        case start_date = "start_date"
        case start_date_local = "start_date_local"
        case timezone = "timezone"
        case utc_offset = "utc_offset"
        case start_latlng = "start_latlng"
        case end_latlng = "end_latlng"
        case location_city = "location_city"
        case location_state = "location_state"
        case location_country = "location_country"
        case start_latitude = "start_latitude"
        case start_longitude = "start_longitude"
        case achievement_count = "achievement_count"
        case kudos_count = "kudos_count"
        case comment_count = "comment_count"
        case athlete_count = "athlete_count"
        case photo_count = "photo_count"
        case trainer = "trainer"
        case commute = "commute"
        case manual = "manual"
        case private_activity = "private"
        case flagged = "flagged"
        case gear_id = "gear_id"
        case from_accepted_tag = "from_accepted_tag"
        case average_speed = "average_speed"
        case max_speed = "max_speed"
        case average_cadence = "average_cadence"
        case average_temp = "average_temp"
        case has_heartrate = "has_heartrate"
        case average_heartrate = "average_heartrate"
        case max_heartrate = "max_heartrate"
        case elev_high = "elev_high"
        case elev_low = "elev_low"
        case pr_count = "pr_count"
        case total_photo_count = "total_photo_count"
        case has_kudoed = "has_kudoed"
        case workout_type = "workout_type"
    }
    
    enum CodingKeysAthlete: String, CodingKey {
        case id = "id"
        case resource_state = "resource_state"
    }
    
    enum CodingKeysMap: String, CodingKey {
        case id = "id"
        case summary_polyline = "summary_polyline"
        case resource_state = "resource_state"
    }
    
    
    // init
    // see https://stackoverflow.com/questions/44450114/how-to-use-swift-4-codable-in-core-data
    // TODO: what happens if it already exists
    required convenience init(from decoder: Decoder) throws {
        
        let key = CodingUserInfoKey.context!
        // get NSManagedObjectContext that has been passed in to the decoder
        guard let context = decoder.userInfo[key] as? NSManagedObjectContext else {
            fatalError()
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "StravaActivity", in: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)

        resource_state = try container.decode(Int.self, forKey: .resource_state)
        external_id = try container.decodeIfPresent(String.self, forKey: .external_id)
        upload_id = try container.decodeIfPresent(Int.self, forKey: .upload_id) ?? 0
        name = try container.decode(String.self, forKey: .name)
        distance = try container.decode(Float.self, forKey: .distance)
        moving_time = try container.decode(Int.self, forKey: .moving_time)
        elapsed_time = try container.decode(Int.self, forKey: .elapsed_time)
        total_elevation_gain = try container.decode(Float.self, forKey: .total_elevation_gain)
        type = try container.decode(String.self, forKey: .type)
        start_date = try container.decode(String.self, forKey: .start_date)
        start_date_local = try container.decode(String.self, forKey: .start_date_local)
        timezone = try container.decode(String.self, forKey: .timezone)
        utc_offset = try container.decode(Float.self, forKey: .utc_offset)
        // TODO: deserializing start/end
        start_latlng = try container.decodeIfPresent([Float].self, forKey: .start_latlng) ?? []
        end_latlng = try container.decodeIfPresent([Float].self, forKey: .end_latlng) ?? []
        
        location_city = try container.decodeIfPresent(String.self, forKey: .location_city)
        location_state = try container.decodeIfPresent(String.self, forKey: .location_state)
        location_country = try container.decodeIfPresent(String.self, forKey: .location_country)

        start_latitude = try container.decodeIfPresent(Float.self, forKey: .start_latitude) ?? 0
        start_longitude = try container.decodeIfPresent(Float.self, forKey: .start_longitude) ?? 0
        
        achievement_count = try container.decode(Int.self, forKey: .achievement_count)
        kudos_count = try container.decode(Int.self, forKey: .kudos_count)
        comment_count = try container.decode(Int.self, forKey: .comment_count)
        athlete_count = try container.decode(Int.self, forKey: .athlete_count)
        photo_count = try container.decode(Int.self, forKey: .photo_count)
        trainer = try container.decode(Bool.self, forKey: .trainer)
        commute = try container.decode(Bool.self, forKey: .commute)
        manual = try container.decode(Bool.self, forKey: .manual)
        flagged = try container.decode(Bool.self, forKey: .flagged)
        gear_id = try container.decodeIfPresent(String.self, forKey: .gear_id)
        from_accepted_tag = try container.decodeIfPresent(Bool.self, forKey: .from_accepted_tag) ?? false
        
        average_speed = try container.decodeIfPresent(Float.self, forKey: .average_speed) ?? 0
        max_speed = try container.decodeIfPresent(Float.self, forKey: .max_speed) ?? 0
        average_cadence = try container.decodeIfPresent(Float.self, forKey: .average_cadence) ?? 0
        average_temp = try container.decodeIfPresent(Float.self, forKey: .average_temp) ?? 0
        
        has_heartrate = try container.decode(Bool.self, forKey: .has_heartrate)
        average_heartrate = try container.decodeIfPresent(Float.self, forKey: .average_heartrate) ?? 0
        max_heartrate = try container.decodeIfPresent(Float.self, forKey: .max_heartrate) ?? 0
        
        elev_high = try container.decodeIfPresent(Float.self, forKey: .elev_high) ?? 0
        elev_low = try container.decodeIfPresent(Float.self, forKey: .elev_low) ?? 0
        
        pr_count = try container.decode(Int.self, forKey: .pr_count)
        total_photo_count = try container.decode(Int.self, forKey: .total_photo_count)
        has_kudoed = try container.decode(Bool.self, forKey: .has_kudoed)
        workout_type = try container.decodeIfPresent(Int.self, forKey: .workout_type) ?? 0
        
        let mapContainer = try container.nestedContainer(keyedBy: CodingKeysMap.self, forKey: .map)
        summary_polyline = try mapContainer.decodeIfPresent(String.self, forKey: .summary_polyline)
        
        let athleteContainer = try container.nestedContainer(keyedBy: CodingKeysAthlete.self, forKey: .athlete)
        athlete_id = try athleteContainer.decode(Int.self, forKey: .id)
        
    }
    
    // MARK: Computed Properties
    
    var path: GMSPath {
        get {
            if summary_polyline == nil {
                return GMSPath()
            }
            return GMSPath(fromEncodedPath: summary_polyline!)!
        }
    }
    
    var startDate: Date { // Local time (including DST!)
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            guard let date = formatter.date(from: start_date_local) else {
                print("something went wrong formatting date for \(self)")
                return Date()
            }
            return date 
        }
    }
    
    var endLocation: CLLocationCoordinate2D {
        get {
            if end_latlng == nil {
                return CLLocationCoordinate2D()
            }
            return CLLocationCoordinate2DMake(CLLocationDegrees(end_latlng![0]), CLLocationDegrees(end_latlng![1]))
        }
    }
    
    var locationString: String {
        get {
            let city = location_city ?? ""
            let state = location_state ?? ""
            let country = location_country ?? ""
            return (city + " " + state + " " + country).trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }
    
    var startLocation: CLLocationCoordinate2D {
        get {
            if start_latlng == nil {
                return CLLocationCoordinate2D()
            }
            return CLLocationCoordinate2DMake(CLLocationDegrees(start_latlng![0]), CLLocationDegrees(start_latlng![1]))
        }
    }
}


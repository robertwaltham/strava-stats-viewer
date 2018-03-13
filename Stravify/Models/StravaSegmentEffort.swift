//
//  StravaSegmentEffort.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-12.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/*
 {
     "id": 35819555034,
     "resource_state": 2,
     "name": "Lower Lonsdale pier",
     "activity": {
         "id": 1440093708,
         "resource_state": 1
     },
     "athlete": {
         "id": 8241500,
         "resource_state": 1
     },
     "elapsed_time": 158,
     "moving_time": 158,
     "start_date": "2018-03-07T01:22:37Z",
     "start_date_local": "2018-03-06T17:22:37Z",
     "distance": 428.7,
     "start_index": 96,
     "end_index": 126,
     "average_cadence": 86.6,
     "average_heartrate": 172.2,
     "max_heartrate": 179.0,
     "segment": {
        "id": 2309502,
        ...
     },
     "kom_rank": null,
     "pr_rank": null,
     "achievements": [],
     "hidden": false
 }
 */


/**
 - See: https://developers.strava.com/docs/reference/#api-models-DetailedSegmentEffort
 */
class StravaSegmentEffort: Decodable {
    let id: Int
    let resource_state: Int
    let name: String
    let activity_id: Int
    let athlete_id: Int
    let elapsed_time: Int
    let moving_time: Int
    let start_date: String
    let start_date_local: String
    let distance: Double
    let start_index: Int
    let end_index: Int
    let average_cadence: Double
    let average_heartrate: Double
    let max_heartrate: Double
    let segment_id: StravaSegment
    let kom_rank: Int?
    let pr_rank: Int?
//    let achievements: []
    let hidden: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case resource_state = "resource_state"
        case name = "name"
        case activity = "activity"
        case athlete = "athlete"
        case elapsed_time = "elapsed_time"
        case moving_time = "moving_time"
        case start_date = "start_date"
        case start_date_local = "start_date_local"
        case distance = "distance"
        case start_index = "start_index"
        case end_index = "end_index"
        case average_cadence = "average_cadence"
        case average_heartrate = "average_heartrate"
        case max_heartrate = "max_heartrate"
        case segment_id = "segment_id"
        case kom_rank = "kom_rank"
        case pr_rank = "pr_rank"
        case hidden = "hidden"

    }
    
    enum CodingKeysAthlete: String, CodingKey {
        case id = "id"
        case resource_state = "resource_state"
    }
    
    enum CodingKeysActivity: String, CodingKey {
        case id = "id"
        case resource_state = "resource_state"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        resource_state = try container.decode(Int.self, forKey: .resource_state)
        name = try container.decode(String.self, forKey: .name)
        elapsed_time = try container.decode(Int.self, forKey: .elapsed_time)
        moving_time = try container.decode(Int.self, forKey: .moving_time)
        start_date = try container.decode(String.self, forKey: .start_date)
        start_date_local = try container.decode(String.self, forKey: .start_date_local)
        distance = try container.decode(Double.self, forKey: .distance)
        start_index = try container.decode(Int.self, forKey: .start_index)
        end_index = try container.decode(Int.self, forKey: .end_index)
        average_cadence = try container.decode(Double.self, forKey: .average_cadence)
        average_heartrate = try container.decode(Double.self, forKey: .average_heartrate)
        max_heartrate = try container.decode(Double.self, forKey: .max_heartrate)
        segment_id = try container.decode(StravaSegment.self, forKey: .segment_id)
        kom_rank = try container.decode(Int.self, forKey: .kom_rank)
        pr_rank = try container.decode(Int.self, forKey: .pr_rank)
        hidden = try container.decode(Bool.self, forKey: .hidden)
        
        let athleteContainer = try container.nestedContainer(keyedBy: CodingKeysAthlete.self, forKey: .athlete)
        athlete_id = try athleteContainer.decode(Int.self, forKey: .id)

        let activityContainer = try container.nestedContainer(keyedBy: CodingKeysActivity.self, forKey: .activity)
        activity_id = try activityContainer.decode(Int.self, forKey: .id)

    }
    
}

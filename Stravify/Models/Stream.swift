//
//  Stream.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

enum StreamType : String, Codable {
    case time               //     integer seconds
    case latlng             //     floats [latitude, longitude]
    case distance           //     float meters
    case altitude           //     float meters
    case velocity_smooth    //     float meters per second
    case heartrate          //     integer BPM
    case cadence            //     integer RPM
    case watts              //     integer watts
    case temp               //     integer degrees Celsius
    case moving             //     boolean
    case grade_smooth       //     float percent
}

enum StreamResolution : String, Codable {
    case low
    case medium
    case high
}

class Stream : Codable, CustomDebugStringConvertible {
    var debugDescription: String {
        get {
            return "<Stream: \(type.rawValue) \(resolution.rawValue) \(original_size):\(data.count > 0 ? data.count : location_data.count)>"
        }
    }
    
    let type: StreamType
    let series_type: String
    let original_size: Int
    let resolution: StreamResolution
    let data: [Double]
    let location_data: [[Double]]
    
    enum CodingKeys: String, CodingKey {
        case type
        case series_type
        case original_size
        case resolution
        case data
        case location_data
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(StreamType.self, forKey: .type)
        series_type = try values.decode(String.self, forKey: .series_type)
        original_size = try values.decode(Int.self, forKey: .original_size)
        resolution = try values.decode(StreamResolution.self, forKey: .resolution)
        
        if type == .latlng {
            location_data = try values.decode([[Double]].self, forKey: .data)
            data = []
        } else {
            data = try values.decode([Double].self, forKey: .data)
            location_data = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(series_type, forKey: .series_type)
        try container.encode(original_size, forKey: .original_size)
        try container.encode(resolution, forKey: .resolution)
        
        if type == .latlng {
            try container.encode(location_data, forKey: .data)
        } else {
            try container.encode(data, forKey: .data)
        }
    }
    
    
}



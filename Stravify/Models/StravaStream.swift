//
//  Stream.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

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
    case low        // 100 points
    case medium     // 1000 points
    case high       // 10000 + points 
}

class StravaStream : NSManagedObject, Decodable {
    override var debugDescription: String {
        get {
            return "<Stream: \(type) \(resolution) \(original_size):\(data.count > 0 ? data.count : location_data.count)>"
        }
    }
    
    @NSManaged var type: String
    @NSManaged var series_type: String
    @NSManaged var original_size: Int
    @NSManaged var resolution: String
    @NSManaged var data: [Double]
    @NSManaged var location_data: [[Double]]
    
    @NSManaged var activity: StravaActivity?
    
    var locationList: [CLLocationCoordinate2D] {
        get {
            return location_data.map { CLLocationCoordinate2DMake(CLLocationDegrees($0[0]), CLLocationDegrees($0[1]))}
        }
    }
    
    var streamType: StreamType {
        get {
            return StreamType(rawValue: type)!
        }
    }
    
    var streamResolution: StreamResolution {
        get {
            return StreamResolution(rawValue: resolution)!
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case series_type
        case original_size
        case resolution
        case data
        case location_data
    }
    
    required convenience init(from decoder: Decoder) throws {
        let key = CodingUserInfoKey.context!
        // get NSManagedObjectContext that has been passed in to the decoder
        guard let context = decoder.userInfo[key] as? NSManagedObjectContext else {
            fatalError()
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "StravaStream", in: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertInto: context)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        series_type = try values.decode(String.self, forKey: .series_type)
        original_size = try values.decode(Int.self, forKey: .original_size)
        resolution = try values.decode(String.self, forKey: .resolution)
        
        if streamType == .latlng {
            location_data = try values.decode([[Double]].self, forKey: .data)
            data = []
        } else {
            data = try values.decode([Double].self, forKey: .data)
            location_data = []
        }
    }
}



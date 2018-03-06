//
//  StravaUser.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-31.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//



import Foundation
import UIKit
import CoreData


/**
 Represents an individual Athlete on Strava
 
 Example JSON:
 
 `{
     "badge_type_id" = 0;
     city = "North Vancouver";
     country = Canada;
     "created_at" = "2015-03-14T21:13:00Z";
     email = "rob@blockoftext.com";
     firstname = Robert;
     follower = "<null>";
     friend = "<null>";
     id = 8241500;
     lastname = Waltham;
     premium = 0;
     profile = "https://dgalywyr863hv.cloudfront.net/pictures/athletes/8241500/2497388/5/large.jpg";
     "profile_medium" = "https://dgalywyr863hv.cloudfront.net/pictures/athletes/8241500/2497388/5/medium.jpg";
     "resource_state" = 2;
     sex = M;
     state = BC;
     "updated_at" = "2018-01-24T23:04:25Z";
     username = "robert_waltham";
 }`
 */
class StravaAthlete : NSManagedObject, Codable {
    
    /**
      - See `https://stackoverflow.com/questions/44450114/how-to-use-swift-4-codable-in-core-data`
     TODO: what happens if decoding fails?
    */
    required convenience init(from decoder: Decoder) throws {
        
        let key = CodingUserInfoKey.context!
        // get NSManagedObjectContext that has been passed in to the decoder
        guard let context = decoder.userInfo[key] as? NSManagedObjectContext else {
            fatalError()
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "StravaAthlete", in: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        resource_state = try container.decode(Int.self, forKey: .resource_state)
        premium = try container.decode(Int.self, forKey: .premium)
        firstname = try container.decode(String.self, forKey: .firstname)
        lastname = try container.decode(String.self, forKey: .lastname)
        profile_medium = try container.decode(String.self, forKey: .profile_medium)
        profile = try container.decode(String.self, forKey: .profile)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        country = try container.decode(String.self, forKey: .country)
        sex = try container.decode(String.self, forKey: .sex)
        email = try container.decode(String.self, forKey: .email)
        created_at = try container.decode(String.self, forKey: .created_at)
        badge_type_id = try container.decode(Int.self, forKey: .badge_type_id)
        
        try context.save()
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case resource_state = "resource_state"
        case premium = "premium"
        case firstname = "firstname"
        case lastname = "lastname"
        case profile_medium = "profile_medium"
        case profile = "profile"
        case city = "city"
        case state = "state"
        case country = "country"
        case sex = "sex"
        case email = "email"
        case created_at = "created_at"
        case badge_type_id = "badge_type_id"
    }
    
    // MARK: Core Data Properties
    
    @NSManaged var id: Int
    @NSManaged var resource_state: Int
    @NSManaged var premium: Int
    @NSManaged var firstname: String
    @NSManaged var lastname: String
    @NSManaged var profile_medium: String
    @NSManaged var profile: String
    @NSManaged var city: String
    @NSManaged var state: String
    @NSManaged var country: String
    @NSManaged var sex: String
    @NSManaged var email: String
    @NSManaged var created_at: String
    @NSManaged var updated_at: String
    @NSManaged var badge_type_id: Int
    
    // MARK: Loaded properties
    var zones: Zones? // Loaded from the API
    
    // MARK: Computed properties
    
    var fullName: String {
        get {
            return firstname + " " + lastname
        }
    }
    
    var location: String {
        get {
            return city + " " + state + ", " + country
        }
    }
    
    var computedZones: [Int] {
        get {
            if let zones = zones {
                return zones.zones.map { $0["min"] ?? 0 }
            } else {
                return []
            }
        }
    }
    
    // TODO: caching
    func getProfileImage(_ done: @escaping (UIImage?) -> Void) {
        let url = URL(string: profile)!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("error getting profile image: \(error?.localizedDescription ?? "no error")")
                done(nil)
                return
            }
            done(UIImage(data: data))
        }.resume()
    }
    
    // TODO: Remove this once encoding isn't needed any more
    func encode(to encoder: Encoder) throws {
        
    }
    
    class Zones : Codable {
        let custom_zones: Int
        let zones: [[String: Int]]
    }
}



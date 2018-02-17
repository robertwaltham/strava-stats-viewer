//
//  StravaUser.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-31.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

/*
 {
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
 }
 */

import Foundation
import UIKit

class Athlete : Codable {
    
    let id: Int
    let resource_state: Int
    let premium: Int

    let firstname: String
    let lastname: String
    
    var fullName: String {
        get {
            return firstname + " " + lastname
        }
    }
    
    let profile_medium: String
    let profile: String
    
    let city: String
    let state: String
    let country: String
    
    var location: String {
        get {
            return city + " " + state + ", " + country
        }
    }
    
    let sex: String
    
    let email: String
    
    let created_at: String
    let updated_at: String
    
    let badge_type_id: Int
    
    // this will be loaded from the api seperately 
    var zones: Zones?
    
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
    
    class Zones : Codable {
        let custom_zones: Int
        let zones: [[String: Int]]
    }
}

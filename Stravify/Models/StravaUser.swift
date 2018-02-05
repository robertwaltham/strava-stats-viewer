//
//  StravaUser.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-04.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

/*
 {
     "access_token" = asdfasdfasdfasdf;
     athlete =     {
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
     };
     "token_type" = Bearer;
 }
 */

class StravaUser: Codable {
    let athlete: Athlete
    let access_token: String
    let token_type: String
}

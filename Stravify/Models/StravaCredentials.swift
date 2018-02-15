//
//  StravaCredentials.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-05.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

struct APICredentials : Codable {
    let CLIENT_SECRET: String
    let ACCESS_TOKEN: String
    let CLIENT_ID: String
    let GMAPS_API: String // google maps API key
}

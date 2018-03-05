//
//  CodingUserInfoKey+Extensions.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-05.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation

// a key to pass in an NSManagedObjectContext to an encoder
extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "context")
}

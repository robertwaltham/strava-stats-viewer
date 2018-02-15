//
//  BundleInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation


class BundleInteractor {
    
    enum BundleInteratorError: Error {
        case invalidCredentials
    }
    
    static func loadCredentialsFromBundle() throws -> APICredentials {
        guard let credentialsPath = Bundle.init(for: self).url(forResource: "credentials", withExtension: "json") else {
            print("credentials not found")
            throw BundleInteratorError.invalidCredentials
        }
        
        let jsonData = try Data(contentsOf: credentialsPath)
        return try JSONDecoder().decode(APICredentials.self, from: jsonData)
    }
}

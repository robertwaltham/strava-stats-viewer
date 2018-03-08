//
//  UIViewController+Extensions.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-07.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation


extension UIViewController {
    
    /**
     Presents an alert for a strava API error. In case of an auth error it will log the user out. 
    */
    func handleFault(_ fault: StravaInteractor.StravaFault, logoutSegueID: String = "logout") {
        let alert = UIAlertController(title: "Fault", message: fault.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .`default`) { alert in
            if fault.type == .authorization {
                self.performSegue(withIdentifier: logoutSegueID, sender: self)
            }
        })
        present(alert, animated: true)
    }
}

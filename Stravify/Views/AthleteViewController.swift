//
//  AthleteViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-14.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit


class AthleteViewController : UIViewController {
    
    var athlete: Athlete?
    
    @IBOutlet var profileImage: UIImageView?
    @IBOutlet var userNameLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if athlete != nil {
            let user: StravaUser? = ServiceLocator.shared.tryGetService()
            athlete = user?.athlete
        }
        
        guard let athlete = athlete else {
            print("no athlete found")
            return
        }
        
        userNameLabel?.text = athlete.firstname + " " + athlete.lastname
        
        let url = URL(string: athlete.profile_medium)!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("error getting profile image")
                return
            }
            DispatchQueue.main.async() { [weak self] in
                self?.profileImage?.image = UIImage(data: data)
            }
        }.resume()
    }
    
}

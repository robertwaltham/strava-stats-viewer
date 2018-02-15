//
//  AthleteViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-14.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit


class AthleteViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var athlete: Athlete?
    
    let activityCellIdentifier = "ActivityCell"
    
    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var locationLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if athlete == nil {
            let user: StravaUser? = ServiceLocator.shared.tryGetService()
            athlete = user?.athlete
        }
        
        guard let athlete = athlete else {
            print("no athlete found")
            return
        }
        
        userNameLabel?.text = athlete.fullName
        
        athlete.getProfileImage { image in
            DispatchQueue.main.async { [weak self] in
                self?.profileImage?.image = image
            }
        }
        
//        StravaInteractor.getActivityList()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: activityCellIdentifier)!
    }
    
}

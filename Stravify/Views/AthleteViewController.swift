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
    
    var activityList: [String] = []
    
    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var locationLabel: UILabel?
    @IBOutlet weak var activityTable: UITableView!
    
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
        locationLabel?.text = athlete.location
        
        athlete.getProfileImage { image in
            DispatchQueue.main.async { [weak self] in
                self?.profileImage?.image = image
            }
        }
        
        try? loadTableData()
        
        // load zones
        if athlete.zones == nil {
            try? StravaInteractor.getZones() { zones in
                athlete.zones = zones
            }
        }
    }
    
    // Cell -> Activity Detail
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let activityView = segue.destination as? ActivityDetailViewController, let cell = sender as? ActivityCell {
            activityView.activityID = cell.activityID
            
            cell.setSelected(false, animated: false)
        }
    }
    
    func loadTableData() throws {
        activityList = try FSInteractor.list(type: Activity.self).reversed()
        
        DispatchQueue.main.async { [weak self] in
            self?.activityTable.reloadData()
        }
    }
    
    @IBAction func loadActivities(_ sender: UIButton) {
        try? StravaInteractor.getActivityList { [weak self] activities in
            do {
                for activity in activities {
                    let activityID = activity.id.description
                    try FSInteractor.save(activity, id: activityID)
                }
                try self?.loadTableData()
            } catch {
                print("error occurred while loading activities: \(error)")
            }
        }
    }
    
    // UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellIdentifier)!
        
        if let activityCell = cell as? ActivityCell {
            let activityID = activityList[indexPath.row]
            let activity = try? FSInteractor.load(type: Activity.self, id: activityID)
            activityCell.activityName.text = activity?.name ?? "No activity name for row: \(indexPath.row)"
            activityCell.activityID = activityID
            activityCell.previewImage.image = activity?.map.path.imageRepresentation(boundingSize: 100)
        
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped on: \(activityList[indexPath.row])")
    }
}

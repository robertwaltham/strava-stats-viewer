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
    
    let activityCellIdentifier = "ActivityCell"
    
    var activityList: [String] = []
    
    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var locationLabel: UILabel?
    @IBOutlet weak var activityTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user: StravaToken = ServiceLocator.shared.getService()
        let athlete = try! user.loadAthlete()
        
        userNameLabel?.text = athlete?.fullName
        locationLabel?.text = athlete?.location
        
        athlete?.getProfileImage { image in
            DispatchQueue.main.async { [weak self] in
                self?.profileImage?.image = image
            }
        }
        
        loadTableData()
        
        // load zones
        if athlete?.zones == nil {
            try? StravaInteractor.getZones() { zones in
                athlete?.zones = zones
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
    
    // Load activity data from disk
    func loadTableData() {
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        queue.async { [weak self] in
            do {
                self?.activityList = try FSInteractor.list(type: Activity.self).reversed()
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityTable.reloadData()
                }
            } catch {
                print("No activities found")
                print(error)
            }
        }
    }
    
    @IBAction func loadActivities(_ sender: UIButton) {
        try? StravaInteractor.getActivityList(20) { [weak self] activities in
            do {
                for activity in activities {
                    let activityID = activity.id.description
                    try FSInteractor.save(activity, id: activityID)
                }
                self?.loadTableData()
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
        let activityID = activityList[indexPath.row]

        if let activityCell = cell as? ActivityCell {
            let queue: DispatchQueue = ServiceLocator.shared.getService()
            queue.async {
                guard let activity = try? FSInteractor.load(type: Activity.self, id: activityID) else {
                    print("Activity not found for ID: \(activityID)")
                    return
                }
                
                let image = activity.map.path.imageRepresentation(boundingSize: 200)
                DispatchQueue.main.async {
                    activityCell.activityName.text = activity.name
                    activityCell.activityID = activityID
                    activityCell.previewImage.image = image
                }
                activityCell.loadWeather(activity: activity)
            }
            
            activityCell.activityName.text = nil
            activityCell.activityID = nil
            activityCell.previewImage.image = nil
            activityCell.weatherLabel.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    // UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped on: \(activityList[indexPath.row])")
    }
}

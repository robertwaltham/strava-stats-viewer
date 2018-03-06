//
//  AthleteViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-14.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit
import CoreData

/**
 User profile view. Displays athlete information and a list of activities
 */
class AthleteViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let activityCellIdentifier = "ActivityCell"
    
    var activityList: [StravaActivity] = []
    
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
    
    // Load activity data from CoreData
    func loadTableData() {
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        queue.async { [weak self] in
            do {
                let context: NSManagedObjectContext = ServiceLocator.shared.getService()
                
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "StravaActivity")
                fetch.returnsObjectsAsFaults = false
                self?.activityList = try context.fetch(fetch) as! [StravaActivity]
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityTable.reloadData()
                }
            } catch {
                print("No activities found")
                print(error)
            }
        }
    }
    
    // Load activities from Strava API
    @IBAction func loadActivities(_ sender: UIButton) {
        try? StravaInteractor.getActivityList(20) { [weak self] activities in
            self?.loadTableData()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellIdentifier)!
        let activity = activityList[indexPath.row]
        if let activityCell = cell as? ActivityCell {

            activityCell.activityName.text = activity.name
            activityCell.activityID = activity.id

            activityCell.weatherLabel.text = nil
            activityCell.loadWeather(activity: activity)

            activityCell.previewImage.image = nil
            let queue: DispatchQueue = ServiceLocator.shared.getService()
            queue.async {
                let image = activity.path.imageRepresentation(boundingSize: 200)
                DispatchQueue.main.async {
                    activityCell.previewImage.image = image
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped on: \(activityList[indexPath.row].name)")
    }
}

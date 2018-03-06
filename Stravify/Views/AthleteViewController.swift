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

import ReactiveCocoa
import ReactiveSwift


/**
 User profile view. Displays athlete information and a list of activities
 */
class AthleteViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let activityCellIdentifier = "ActivityCell"
    
    var activityList: [StravaActivity] = []
    var viewModelList: [Int: ActivityViewModel] = [:]
    
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
        try? StravaInteractor.getActivityList(40) { [weak self] activities in
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
            let viewModel: ActivityViewModel
            if viewModelList.keys.contains(activity.id) {
                viewModel = viewModelList[activity.id]!
            } else {
                viewModel = ActivityViewModel(activity: activity)
                viewModelList[activity.id] = viewModel
            }
            
            activityCell.viewModel = viewModel
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

/**
 Table Cell to display activity information and weather
 */
class ActivityCell: UITableViewCell {
    
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var weatherLabel: UILabel!

    var viewModel: ActivityViewModel? {
        didSet {
            configureFromViewModel()
        }
    }
    
    var activityID : Int? {
        get {
            return viewModel?.activity.id
        }
    }
    
    private func configureFromViewModel() {
        activityName.text = viewModel?.name
        
        viewModel?
            .imageSignal()
            .take(until: reactive.prepareForReuse)
            .startWithResult { result in
                self.previewImage.image = result.value
        }
        
        viewModel?
            .weatherSignal()
            .take(until: reactive.prepareForReuse)
            .startWithResult { result in
                self.weatherLabel.text = result.value
        }
    }
}

/**
 View model for activity cell. Provides async loading of weather and images.
 */
class ActivityViewModel {
    let activity: StravaActivity
    private var image: UIImage? = nil
    private var weather: String? = nil
    
    init(activity: StravaActivity) {
        self.activity = activity
    }
    
    var name: String {
        get {
            return activity.name
        }
    }
    
    /**
     Generates the image preview for the cell
    */
    func imageSignal() -> SignalProducer<UIImage, NSError> {
        return SignalProducer { observer, disposable in
            if let image = self.image {
                observer.send(value: image)
            } else {
                let queue: DispatchQueue = ServiceLocator.shared.getService()
                queue.async {
                    let image = self.activity.path.imageRepresentation(boundingSize: 200)
                    DispatchQueue.main.async {
                        observer.send(value: image)
                    }
                    self.image = image
                }
            }
        }
    }
    
    /**
     Loads hourly weather data for the activity
     */
    func weatherSignal() -> SignalProducer<String, NSError> {
        return SignalProducer { observer, disposable in
            if let weather = self.weather {
                observer.send(value: weather)
            } else {
                do {
                    try WeatherInteractor.weather(activity: self.activity) { hourlyWeather in
                        DispatchQueue.main.async {
                            if let hourlyWeather = hourlyWeather {
                                if hourlyWeather.weather == "NA" {
                                    self.weather = "\(hourlyWeather.temp) ºC"
                                } else {
                                    self.weather = "\(hourlyWeather.temp) ºC - \(hourlyWeather.weather)"
                                }
                            } else {
                                self.weather = ""
                            }
                            observer.send(value: self.weather!)
                        }
                    }
                } catch {
                    observer.send(error: error as NSError)
                }
            }
        }
    }
}

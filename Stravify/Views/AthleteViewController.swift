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
    
    var viewModelList: [Int: ActivityViewModel] = [:]
    
    var activityCount: Int = 0
    var loadedPages: [Int] = []
    
    // LIFO stack for loading remote data
    // Currently used for weather loading - most recently queued should show up
    // Only one task loads at a time 
    var dataTasks: [String: URLSessionDataTask] = [:]
    var taskOrder: [String] = []
    var loadingTask: URLSessionDataTask? = nil
    
    let PAGE_SIZE = 10
    
    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var locationLabel: UILabel?
    @IBOutlet weak var activityTable: UITableView!
    
    @IBOutlet weak var activityCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user: StravaToken = ServiceLocator.shared.getService()
        guard let athlete = try! user.loadAthlete() else {
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
        
        // load zones
        if athlete.zones == nil {
            try? StravaInteractor.getZones() { zones, fault in
                if let zones = zones {
                    athlete.zones = zones["heart_rate"]
                }
            }
        }
        
        // load stats 
        try? StravaInteractor.getStats(id: athlete.id) { [weak self] stats, fault in
            guard fault == nil else {
                self?.handleFault(fault!)
                return
            }
            
            if let stats = stats {
                athlete.stats = stats
                self?.activityCount = stats.all_run_totals.count
                
                try? StravaInteractor.getActivityList(self?.PAGE_SIZE ?? 10) { [weak self] activities, fault in
                    guard fault == nil else {
                        self?.handleFault(fault!)
                        return
                    }
                    
                    self?.loadedPages.append(1)
                    DispatchQueue.main.async { [weak self] in
                        CoreDataInteractor.saveContext(container: ServiceLocator.shared.getService())
                        self?.activityTable.reloadData()
                    }
                }
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
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityCount
    }
    
    
    /**
     Loads StravaActivity for the given IndexPath, based on ID order
     
     Also precaches the next page, if it hasn't been loaded yet
    */
    private func loadActivity(indexPath: IndexPath) -> StravaActivity? {
        
        // precache next page
        let nextPage = (indexPath.row / PAGE_SIZE) + 2 // starts at 1
        
        if !loadedPages.contains(nextPage) {
            self.loadedPages.append(nextPage)
            try? StravaInteractor.getActivityList(PAGE_SIZE, nextPage) { [weak self] activities, fault in
                guard fault == nil else {
                    self?.handleFault(fault!)
                    return
                }
                CoreDataInteractor.saveContext(container: ServiceLocator.shared.getService())
            }
        }
        
        // load activity
        let context: NSManagedObjectContext = ServiceLocator.shared.getService()
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "StravaActivity")
        let sort = NSSortDescriptor(key: "id", ascending: false)
        fetch.sortDescriptors = [sort]
        fetch.fetchOffset = indexPath.row
        fetch.fetchLimit = 1
        
        guard let results = try? context.fetch(fetch) as! [StravaActivity], results.count > 0 else {
            print("no activity found for \(indexPath.row)")
            return nil
        }
        
        return results[0]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellIdentifier)!
        if let activityCell = cell as? ActivityCell {
            activityCell.weatherLabel.text = "" // clear weather

            if let activity = loadActivity(indexPath: indexPath) {
                
                let viewModel: ActivityViewModel
                if viewModelList.keys.contains(activity.id) {
                    viewModel = viewModelList[activity.id]!
                } else {
                    viewModel = ActivityViewModel(activity: activity, parent: self)
                    viewModelList[activity.id] = viewModel
                }
                
                activityCell.viewModel = viewModel
            } else {
                activityCell.activityName.text = ""
                activityCell.previewImage.image = nil
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    // MARK: Queue
    
    fileprivate func enqueue(task: URLSessionDataTask, key: String) {
        if loadingTask == nil {
            print("starting task \(key) ")
            loadingTask = task
            task.resume()
        } else {
            if !isQueued(key: key) {
                dataTasks[key] = task
                taskOrder.append(key)
                print("queueing task \(key) (\(dataTasks.count))")
            }
        }
    }
    
    fileprivate func isQueued(key: String) -> Bool {
        return dataTasks.keys.contains(key)
    }
    
    fileprivate func markDone() {
        if dataTasks.count > 0 {
            let nextKey = taskOrder.popLast() ?? ""
            loadingTask = dataTasks.removeValue(forKey: nextKey)
            loadingTask?.resume()
            print("resuming task \(nextKey) (\(dataTasks.count))")
        } else {
            print("all tasks done")
            loadingTask = nil
        }
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
    weak var parent: AthleteViewController?
    private var image: UIImage? = nil
    private var weather: String? = nil
    
    init(activity: StravaActivity, parent: AthleteViewController) {
        self.activity = activity
        self.parent = parent
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
                    let key = self.activity.id.description
                    
                    // if there's a queued task then don't add another one
                    guard let parent = self.parent, !parent.isQueued(key: key) else {
                        return
                    }
                    
                    let task = try WeatherInteractor.weather(activity: self.activity) { hourlyWeather, network in
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
                        
                        // if a network load was used, flag it as done
                        if network {
                            parent.markDone()
                        }
                    }
                    
                    // queue task for loading
                    if let task = task {
                        parent.enqueue(task: task, key: key)
                    }
                } catch {
                    observer.send(error: error as NSError)
                }
            }
        }
    }
}

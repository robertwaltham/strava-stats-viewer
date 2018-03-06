//
//  ActivityCell.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit

/**
 Table Cell to display activity information and weather
 */
class ActivityCell: UITableViewCell {
    
    var activityID: Int?
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var weatherLabel: UILabel!
    
    /**
     Loads hourly weather data for the activity
     
     TODO: Delegating this to a view model to fix data race when scrolling table
     
     - parameter activity: The activity to load weather for. Must have associated GPS data.
    */
    func loadWeather(activity: StravaActivity) {
        try? WeatherInteractor.weather(activity: activity) { [weak self] hourlyWeather in
            DispatchQueue.main.async {
                if let hourlyWeather = hourlyWeather {
                    if hourlyWeather.weather == "NA" {
                        self?.weatherLabel.text = "\(hourlyWeather.temp) ºC"
                    } else {
                        self?.weatherLabel.text = "\(hourlyWeather.temp) ºC - \(hourlyWeather.weather)"
                    }
                } else {
                    self?.weatherLabel.text = ""
                }
            }
        }
    }
    
}

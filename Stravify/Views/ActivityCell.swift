//
//  ActivityCell.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit

class ActivityCell: UITableViewCell {
    
    var activityID: String? 
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var weatherLabel: UILabel!
    
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

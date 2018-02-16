//
//  HeatMapViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class HeatMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadButton: UIButton!
    
    let queue = DispatchQueue(label: "com.blockoftext.heatmap")
    
    var locations: [GMUWeightedLatLng] = []
    var bounds = GMSCoordinateBounds()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func load(_ sender: UIButton) {
        activityIndicator.startAnimating()
        loadButton.isEnabled = false
        
        locations = []
        bounds = GMSCoordinateBounds()
        
        queue.async {
            try? StravaInteractor.getActivityList { [unowned self] activities in
                let group = DispatchGroup()
                
                for activity in activities {
                    group.enter()
                    try? StravaInteractor.getStream(activity: activity, type: .latlng, resolution: .low) { streams in
                        defer {
                            group.leave()
                        }
                        
                        guard let latlng = streams.first(where: { $0.type == .latlng }) else {
                            print("why is there no latlong stream for \(activity.id)?")
                            return
                        }
                        
                    }
                }
                
                group.notify(queue: .main) {
                    self.activityIndicator.stopAnimating()
                    self.loadButton.isEnabled = true
                    
                    
                }
                
            }
        }
    }
    
    
}

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
    
    private var locations: [GMUWeightedLatLng] = []
    private var bounds = GMSCoordinateBounds()
    private var heatMapLayer: GMUHeatmapTileLayer!
    
    private var gradientColors = [UIColor.green, UIColor.yellow, UIColor.red]
    private var gradientStartPoints = [0.000001, 0.02, 0.2] as [NSNumber]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        heatMapLayer = GMUHeatmapTileLayer()
        heatMapLayer.gradient = GMUGradient(colors: gradientColors,
                                            startPoints: gradientStartPoints,
                                            colorMapSize: 256)
        heatMapLayer.opacity = 0.95
        heatMapLayer.radius = 15

    }
    
    @IBAction func load(_ sender: UIButton) {
        activityIndicator.startAnimating()
        loadButton.isEnabled = false
        
        locations = []
        bounds = GMSCoordinateBounds()
        
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        queue.async {
            try? StravaInteractor.getActivityList(20) { [unowned self] activities in
                let group = DispatchGroup()
                
                for activity in activities {
                    group.enter()
                    
                    // load saved stream
                    let savedStream = try? FSInteractor.load(type: Stream.self, id: Stream.idForSaving(activity, .latlng, .low))
                    if let stream = savedStream {
                        for coordinate in stream.locationList {
                            self.bounds = self.bounds.includingCoordinate(coordinate)
                            self.locations.append(GMUWeightedLatLng(coordinate: coordinate, intensity: 1))
                        }
                        group.leave()
                    // else grab from API
                    } else {
                        try? StravaInteractor.getStream(activity: activity, type: .latlng, resolution: .low) { streams in
                            defer {
                                group.leave()
                            }
                            
                            guard let latlng = streams.first(where: { $0.type == .latlng }) else {
                                print("why is there no latlong stream for \(activity.id)?")
                                return
                            }
                            
                            for coordinate in latlng.locationList {
                                self.bounds = self.bounds.includingCoordinate(coordinate)
                                self.locations.append(GMUWeightedLatLng(coordinate: coordinate, intensity: 1))
                            }
                            
                            try? FSInteractor.save(latlng, id: Stream.idForSaving(activity, .latlng, .low))
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.activityIndicator.stopAnimating()
                    self.loadButton.isEnabled = true
                    
                    print("done: loc count: \(self.locations.count) bounds: \(self.bounds.northEast);\(self.bounds.southWest)")
                    self.heatMapLayer.weightedData = self.locations
                    self.heatMapLayer.clearTileCache()
                    self.heatMapLayer.map = self.mapView
                    self.mapView.animate(with: GMSCameraUpdate.fit(self.bounds, withPadding: 15))
                }
                
            }
        }
    }
    
    
}

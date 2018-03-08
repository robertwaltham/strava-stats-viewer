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
import CoreData

/**
 Displays a heat map of recent activities
 */
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
        loadHeatMap()
    }
    
    private func loadHeatMap() {
        activityIndicator.startAnimating()
        loadButton.isEnabled = false
        
        locations = []
        bounds = GMSCoordinateBounds()
        
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        queue.async { [weak self] in
            guard let weakself = self else {
                return
            }
            
            let context: NSManagedObjectContext = ServiceLocator.shared.getService()
            
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "StravaActivity")
            fetch.returnsObjectsAsFaults = false
            let activities: [StravaActivity]
            do {
                activities = try context.fetch(fetch) as! [StravaActivity]
            } catch {
                print("Activity load failed: \(error)")
                activities = []
            }
            
            let group = DispatchGroup()
            
            for activity in activities {
                group.enter()
                
                // load saved stream
                let savedStream = activity.streams?.first(where: { $0.streamType == .latlng })
                if let stream = savedStream {
                    for coordinate in stream.locationList {
                        weakself.bounds = weakself.bounds.includingCoordinate(coordinate)
                        weakself.locations.append(GMUWeightedLatLng(coordinate: coordinate, intensity: 1))
                    }
                    group.leave()
                    // else grab from API
                } else {
                    try? StravaInteractor.getStream(activity: activity, type: .latlng, resolution: .low) { streams, fault in
                        defer {
                            group.leave()
                        }
                        
                        guard fault == nil else {
                            weakself.handleFault(fault!)
                            return
                        }

                        guard let streams = streams, let latlng = streams.first(where: { $0.streamType == .latlng }) else {
                            print("why is there no latlong stream for \(activity.id)?")
                            return
                        }
                        
                        for stream in streams {
                            activity.streams?.insert(stream)
                        }

                        for coordinate in latlng.locationList {
                            weakself.bounds = weakself.bounds.includingCoordinate(coordinate)
                            weakself.locations.append(GMUWeightedLatLng(coordinate: coordinate, intensity: 1))
                        }

                    }
                }
            }
            
            group.notify(queue: .main) {
                weakself.activityIndicator.stopAnimating()
                weakself.loadButton.isEnabled = true
                
                print("done: loc count: \(weakself.locations.count) bounds: \(weakself.bounds.northEast);\(weakself.bounds.southWest)")
                weakself.heatMapLayer.weightedData = weakself.locations
                weakself.heatMapLayer.clearTileCache()
                weakself.heatMapLayer.map = weakself.mapView
                weakself.mapView.animate(with: GMSCameraUpdate.fit(weakself.bounds, withPadding: 15))
            }
        }
    }
    
}

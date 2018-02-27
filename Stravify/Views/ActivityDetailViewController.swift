//
//  ActivityDetailViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-15.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import ReactiveCocoa
import ReactiveSwift

class ActivityDetailViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var viewSelector: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    enum ActivityDisplayType: Int {
        case none = 0
        case heartRate
        case speed
        case elevation
    }
    
    private let hrColors = [
        UIColor.white,
        UIColor.gray,
        UIColor.blue,
        UIColor.green,
        UIColor.yellow,
        UIColor.red
    ]
    
    var activityID: String?
    private var activity: Activity?
    private var polyline: GMSPolyline?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let activityID = activityID else {
            print("no activityID found")
            return
        }
        
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        
        queue.async { [unowned self] in
            self.activity = try? FSInteractor.load(type: Activity.self, id: activityID)
            
            guard let activity = self.activity else {
                print("no activity loaded")
                return
            }
            
            // Set up bounds and start/finish marker
            DispatchQueue.main.async { [unowned self] in
                self.navigationItem.title = activity.name
                
                // set up camera
                let path = activity.map.path
                let bounds = GMSCoordinateBounds(path: path)
                let update = GMSCameraUpdate.fit(bounds, withPadding: 20)
                self.mapView.moveCamera(update)
                
                // start marker
                let start = GMSMarker(position: activity.startLocation)
                start.title = "Start"
                start.icon = GMSMarker.markerImage(with: .green)
                start.map = self.mapView
                
                // end marker
                let end = GMSMarker(position: activity.endLocation)
                end.title = "End"
                end.icon = GMSMarker.markerImage(with: .red)
                end.map = self.mapView
            }

            // load high res stream
            self.loadStream(activity: activity, type: .latlng, resolution: .high) { [unowned self] stream in
                let path = GMSMutablePath()
                for point in stream.locationList {
                    path.add(point)
                }
                
                // create polyline
                self.polyline = GMSPolyline(path: path)
                self.polyline?.map = self.mapView
                
                // event for control change
                self.viewSelector.reactive.controlEvents(.valueChanged).observeValues { [weak self] control in
                    self?.updateMapDisplay(type: ActivityDisplayType(rawValue: control.selectedSegmentIndex) ?? .none)
                }
            }
        }
    }
    
    // Attempts to load stream from disk, else loads from API
    private func loadStream(activity: Activity, type: StreamType, resolution: StreamResolution, done: @escaping (Stream) -> Void) {
        let queue: DispatchQueue = ServiceLocator.shared.getService()
        queue.async {
            let key = Stream.idForSaving(activity, type, resolution)
            let cachedStream = try? FSInteractor.load(type: Stream.self, id: key)
            if let cachedStream = cachedStream {
                DispatchQueue.main.async {
                    done(cachedStream)
                }
            } else {
                try? StravaInteractor.getStream(activity: activity, type: type, resolution: .high) { streams in
                    guard let stream = streams.first(where: { $0.type == type }) else {
                        print("why is there no \(type.rawValue) stream for \(activity.id)?")
                        return
                    }
                    DispatchQueue.main.async {
                        done(stream)
                    }
                    // save to disk
                    try? FSInteractor.save(stream, id: key)
                }
            }
        }

    }

    // Updates the polyline styling based on stream type
    private func updateMapDisplay(type: ActivityDisplayType) {
        guard let activity = activity else {
            print("why is there no activity?")
            return
        }
        
        if type == .none {
            polyline?.spans = nil
            polyline?.strokeWidth = 2
        } else {
            viewSelector.isEnabled = false
            activityIndicator.startAnimating()
            
            let streamType: StreamType
            switch type {
            case .elevation:
                streamType = .altitude
            case .heartRate:
                streamType = .heartrate
            case .none:
                streamType = .distance
            case .speed:
                streamType = .moving
            }
            loadStream(activity: activity, type: streamType, resolution: .high) { [unowned self] stream in
                if type == .speed {
                    self.polyline?.spans = self.computeStyles(stream: stream)
                } else if type == .heartRate {
                    let user: StravaUser? = ServiceLocator.shared.tryGetService()
                    let zones = user?.athlete.computedZones ?? [500]
                    self.polyline?.spans = self.computeStylesForZones(stream: stream, zones: zones)
                }  else {
                    self.polyline?.spans = self.computeStyles(stream: stream)
                }
                self.polyline?.strokeWidth = 5
                
                self.viewSelector.isEnabled = true
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    // compute polyline styles for heart rate zones
    private func computeStylesForZones(stream: Stream, zones: [Int]) -> [GMSStyleSpan] {
        return stream.data.map { value in
            var color = hrColors.first
            for (i, zone) in zones.enumerated() {
                if Double(zone) > value {
                    break
                }
                color = hrColors[i]
            }
            return GMSStyleSpan(color: color ?? UIColor.white)
        }
    }
    
    // compoute polyline styles for relative speed and elevation
    private func computeStyles(stream: Stream) -> [GMSStyleSpan] {
        
        var max: Double = 0
        var min: Double = Double.greatestFiniteMagnitude
        
        for value in stream.data {
            if value > max {
                max = value
            }
            
            if value < min {
                min = value
            }
        }
        
        return stream.data.map { value in
            let color = UIColor(hue: 0.3, saturation: CGFloat((value - min) / max), brightness: 1, alpha: 1)
            return GMSStyleSpan(color: color)
        }
    }
}

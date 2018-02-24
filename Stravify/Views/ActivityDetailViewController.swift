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
        
        activity = try? FSInteractor.load(type: Activity.self, id: activityID)
        
        guard let activity = activity else {
            print("no activity loaded")
            return
        }
        
        try? WeatherInteractor.weather(activity: activity) { weather in
            print(weather)
        }
        
        self.navigationItem.title = activity.name
        
        // set up camera
        let path = activity.map.path
        let bounds = GMSCoordinateBounds(path: path)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 20)
        mapView.moveCamera(update)
        
        // start marker
        let start = GMSMarker(position: activity.startLocation)
        start.title = "Start"
        start.icon = GMSMarker.markerImage(with: .green)
        start.map = mapView
        
        // end marker
        let end = GMSMarker(position: activity.endLocation)
        end.title = "End"
        end.icon = GMSMarker.markerImage(with: .red)
        end.map = mapView
        
        // draw unstyled line
        updateMapDisplay(type:.none)

        // event for control change
        viewSelector.reactive.controlEvents(.valueChanged).observeValues { [weak self] control in
            self?.updateMapDisplay(type: ActivityDisplayType(rawValue: control.selectedSegmentIndex) ?? .none)
        }
    }
    
    private func updateMapDisplay(type: ActivityDisplayType) {
        guard let activity = activity else {
            print("why is there no activity?")
            return
        }
        
        polyline?.map = nil // clear old polyline
        
        if type == .none {
            polyline = GMSPolyline(path: activity.map.path)
            polyline?.map = mapView
        } else {
            viewSelector.isEnabled = false
            activityIndicator.startAnimating()
            
            let streamType: StreamType = type == .heartRate ? .heartrate : .velocity_smooth
            try? StravaInteractor.getStream(activity: activity, type: streamType, resolution: .low) { [weak self] streams in
                guard let stream = streams.first(where: { $0.type == streamType }) else {
                    print("why is there no \(streamType.rawValue) stream for \(activity.id)?")
                    return
                }
                
                DispatchQueue.main.async {
                    let polyline = GMSPolyline(path: activity.map.path)
                    
                    if type == .speed {
                        polyline.spans = self?.computeStyles(stream: stream)
                    } else {
                        let user: StravaUser? = ServiceLocator.shared.tryGetService()
                        let zones = user?.athlete.computedZones ?? [500]
                        polyline.spans = self?.computeStylesForZones(stream: stream, zones: zones)
                    }
                    polyline.map = self?.mapView
                    polyline.strokeWidth = 5
                    self?.polyline = polyline
                    
                    self?.viewSelector.isEnabled = true
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func computeStylesForZones(stream: Stream, zones: [Int]) -> [GMSStyleSpan] {
        print(zones)
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
        
        print("max: \(max) min: \(min)")
        
        return stream.data.map { value in
            let color = UIColor(hue: 0.3, saturation: CGFloat((value - min) / max), brightness: 1, alpha: 1)
            return GMSStyleSpan(color: color)
        }
    }
}

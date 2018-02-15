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

class ActivityDetailViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    var activityID: String?
    private var activity: Activity?
    
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
        
        nameLabel.text = activity.name
        distanceLabel.text = "\(activity.distance)"
        
        let path = activity.map.path
        let bounds = GMSCoordinateBounds(path: path)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 10)
        mapView.moveCamera(update)
        
        let polyline = GMSPolyline(path: path)
        polyline.map = mapView
    }
}

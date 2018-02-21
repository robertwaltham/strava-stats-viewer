//
//  PolyLineView.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-19.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit
import GoogleMaps

class PolyLineView: UIView {

    var polyline: GMSPolyline? = nil
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let polyline = polyline,
            let path = polyline.path else {
            return
        }
        
        // compute bounds
        var (maxLat, maxLong, minLat, minLong) = (-Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude)
        for i in 0..<path.count() {
            let coord = path.coordinate(at: i)
            
            maxLat = max(maxLat, coord.latitude)
            maxLong = max(maxLong, coord.longitude)
            minLat = min(minLat, coord.latitude)
            minLong = min(minLong, coord.longitude)
        }
        
        // scale coords
        var scaledCoords: [CGPoint] = []
        let (widthDegrees, heightDegrees) = (maxLat - minLat, maxLong - minLong)
        let (widthRatio, heightRatio) = (Double(rect.size.width) / widthDegrees, Double(rect.size.height) / heightDegrees)
        for i in 0..<path.count() {
            let coord = path.coordinate(at: i)
            
            let result = CGPoint(x: (coord.latitude - minLat) * widthRatio,
                                 y: (coord.longitude - minLong) * heightRatio)
            scaledCoords.append(result)
        }
        
        // draw
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 2
        bezierPath.move(to: scaledCoords[0])
        for coord in scaledCoords.suffix(from: 1) {
            bezierPath.addLine(to: coord)
        }
        UIColor.black.setStroke()
        bezierPath.stroke()
    }

}

//
//  GMSPath+Extensions.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-02-21.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit
import GoogleMaps

extension GMSPath {
    
    func imageRepresentation(boundingSize: Double) -> UIImage {

        // compute bounds
        var (maxLat, maxLong, minLat, minLong) = (-Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude)
        
        for i in 0..<count() {
            let coord = coordinate(at: i)
            
            maxLat = max(maxLat, coord.latitude)
            maxLong = max(maxLong, coord.longitude)
            minLat = min(minLat, coord.latitude)
            minLong = min(minLong, coord.longitude)
        }

        // scale coords
        var scaledCoords: [CGPoint] = []
        let (heightDegrees, widthDegrees) = (maxLat - minLat, maxLong - minLong)
        let aspecRatio = (heightDegrees * 2) / widthDegrees
        
        let imageWidth: Double, imageHeight: Double
        if aspecRatio > 1 {
            imageHeight = boundingSize
            imageWidth = boundingSize / aspecRatio
        } else {
            imageWidth = boundingSize
            imageHeight = boundingSize * aspecRatio
        }
        
        let (widthRatio, heightRatio) = (imageWidth / widthDegrees, imageHeight / heightDegrees)
        for i in 0..<count() {
            let coord = coordinate(at: i)
            let result = CGPoint(x: (coord.longitude - minLong) * widthRatio,
                                 y: imageHeight - ((coord.latitude - minLat) * heightRatio))
            scaledCoords.append(result)
        }
        
        // draw
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imageWidth, height: imageHeight))
        return renderer.image { ctx in
            ctx.cgContext.move(to: scaledCoords[0])
            for coord in scaledCoords.suffix(from: 1) {
                ctx.cgContext.addLine(to: coord)
            }
            ctx.cgContext.setStrokeColor(UIColor.gray.cgColor)
            ctx.cgContext.setLineWidth(2)
            
            ctx.cgContext.drawPath(using: .stroke)
        }
    }
}


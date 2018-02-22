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
    
}

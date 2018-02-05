//
//  ViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loadActivities(sender: UIButton) {
        do {
            try StravaInteractor.getActivityList()
        } catch StravaInteractor.StravaInteratorError.notAuthenticated {
            print("Not logged in")
        } catch {
            print("something bad happened")
        }
    }
    
    @IBAction func loadSavedCredentials(sender: UIButton) {
        if let user = ServiceLocator.shared.tryGetService() as StravaUser? {
            print("already logged in as: \(user.athlete.firstname)")
        } else {
            do {
                let user = try FSInteractor.load(type: StravaUser.self, id: "user")
                ServiceLocator.shared.registerService(service: user)
                print("logged in as: \(user.athlete.firstname)")
            } catch {
                print("no user found: \(error.localizedDescription)")
            }
        }
    }
}


//
//  ViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit

import ReactiveSwift

/**
 Landing view for the app. Displays a carousel of motivational images.
 */
class LandingViewController: UIViewController {
    
    @IBOutlet weak var background: UIImageView?
    
    let scheduler: QueueScheduler
    var imageTransition: Disposable? = nil
    
    // Images contained in "Assets" asset bundle
    static let bgimages = ["bg_1", "bg_2", "bg_3"]
    static let transitionTime: Double = 5
    
    var imageIndex = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        scheduler = QueueScheduler(qos: .default, name: "com.blockoftext.queue", targeting: DispatchQueue.main)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        scheduler = QueueScheduler(qos: .default, name: "com.blockoftext.queue", targeting: DispatchQueue.main)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
        
        // Observer for login notification
        NotificationCenter.default.addObserver(forName: .didLogIn, object: nil, queue: OperationQueue.main) { note in
            
            guard let user = note.object as? StravaToken else {
                print("invalid object sent as user notification")
                return
            }
            // register active user
            // TODO: refactor authentication into an interactor
            ServiceLocator.shared.registerService(service: user)
            try! FSInteractor.save(user, id: "user")
            
            // Display Tab View
            DispatchQueue.main.async { [unowned self] in
                self.performSegue(withIdentifier: "LandingToNav", sender: self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start carousel image transition
        let startTime =  Date().addingTimeInterval(LandingViewController.transitionTime)
        let interval = DispatchTimeInterval.seconds(Int(LandingViewController.transitionTime))
        imageTransition = scheduler.schedule(after: startTime, interval: interval){ [unowned self] in
            guard let background = self.background else {
                fatalError("wtf background image view not found")
            }
            self.imageIndex = (self.imageIndex + 1) % LandingViewController.bgimages.count
            let newImage = UIImage(named: LandingViewController.bgimages[self.imageIndex])
            UIView.transition(with: background,
                              duration:0.5,
                              options: .transitionCrossDissolve,
                              animations: { background.image = newImage },
                              completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let imageTransition = imageTransition {
            imageTransition.dispose()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loadSavedCredentials(sender: UIButton) {
        // This shouldn't happen - means user has already logged in
        if let user = ServiceLocator.shared.tryGetService() as StravaToken? {
            print("already logged in as: \(user.athlete_id)")
        } else {
            do {
                let user = try FSInteractor.load(type: StravaToken.self, id: "user")
                ServiceLocator.shared.registerService(service: user)
                print("logged in as: \(user.athlete_id)")
                performSegue(withIdentifier: "LandingToNav", sender: self)
            } catch {
                // TODO: present alert to user, and/or hide button when file doesn't exist
                print("no user found: \(error.localizedDescription)")
            }
        }
    }
}


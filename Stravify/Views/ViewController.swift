//
//  ViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit

import ReactiveSwift

class ViewController: UIViewController {
    
    @IBOutlet var background: UIImageView?
    
    let scheduler: QueueScheduler
    var imageTransition: Disposable? = nil
    
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
        
        NotificationCenter.default.addObserver(forName: .didLogIn, object: nil, queue: OperationQueue.main) { note in
            
            guard let user = note.object as? StravaUser else {
                print("invalid object sent as user notification")
                return
            }
            // register active user
            // TODO: refactor authentication into an interactor
            ServiceLocator.shared.registerService(service: user)
            try! FSInteractor.save(user, id: "user")
            print("logged in as: \(user.athlete.firstname)")
            
            DispatchQueue.main.async { [unowned self] in
                self.performSegue(withIdentifier: "LandingToNav", sender: self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start bg transition
        let startTime =  Date().addingTimeInterval(ViewController.transitionTime)
        let interval = DispatchTimeInterval.seconds(Int(ViewController.transitionTime))
        imageTransition = scheduler.schedule(after: startTime, interval: interval){ [unowned self] in
            guard let background = self.background else {
                print("wtf image view not found")
                return
            }
            self.imageIndex = (self.imageIndex + 1) % ViewController.bgimages.count
            let newImage = UIImage(named: ViewController.bgimages[self.imageIndex])
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
                performSegue(withIdentifier: "LandingToNav", sender: self)
            } catch {
                print("no user found: \(error.localizedDescription)")
            }
        }
    }
}


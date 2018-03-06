//
//  AuthViewController.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
    static let didLogIn = Notification.Name("didLogIn")
}

/**
    View Controller for displaying the oAuth web page for Strava
 */
class AuthViewController: UIViewController, UIWebViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = view as? UIWebView {
            view.delegate = self
            view.loadRequest(try! StravaInteractor.createAuthenticationURLRequest())
        } else {
            fatalError("why isn't \(view) a UIWebView?")
        }
    }
    
    @IBAction func cancel (sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: UIWebViewDelegate
    
    /**
     When the web view tries to load a request, check that it's the callback url for successful authentication and intercept
     Instead of loading the callback, post notification that login is successful 
     
     TODO: Handle when the user presses decline
     */
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url, StravaInteractor.isCallbackURL(url) {
            StravaInteractor.getAuthenitcationTokenFromCode(redirectURL: url, done: {
                [weak presentingViewController] (user) in
                
                presentingViewController?.dismiss(animated: true) {
                    NotificationCenter.default.post(name: .didLogIn, object: user)
                }
            })
            return false 
        }
        return true
    }
}


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

class AuthViewController: UIViewController, UIWebViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = view as? UIWebView {
            view.delegate = self
            view.loadRequest(try! StravaInteractor.createAuthenticationURLRequest())
        } else {
            print("why isn't this a UIWebView?")
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel (sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    // UIWebViewDelegate
    
    // TODO: Handle when the user presses decline 
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


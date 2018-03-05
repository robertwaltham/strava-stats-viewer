//
//  AppDelegate.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-01-17.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // load credentials and api keys
        do {
            let credentials = try BundleInteractor.loadCredentialsFromBundle()
            ServiceLocator.shared.registerService(service: credentials)
            
            GMSServices.provideAPIKey(credentials.GMAPS_API)
        } catch {
            fatalError("failed to load credentials.json from bundle")
        }
        
        // create shared queue
        let queue = DispatchQueue(label: "com.blockoftext.stravify")
        ServiceLocator.shared.registerService(service: queue)
        
        // load filtered weather stations
        let cachedStations = try? FSInteractor.load(type: [WeatherStation].self, id: "filtered_stations")
        if let cachedStations = cachedStations {
            ServiceLocator.shared.registerService(service: cachedStations)
        } else {
            do {
                let stations = try WeatherInteractor.readStationInventory()
                let filteredStations = WeatherInteractor.filterStationInventory(stations: stations)
                try FSInteractor.save(filteredStations, id: "filtered_stations")
                ServiceLocator.shared.registerService(service: filteredStations)
            } catch {
                print(error)
            }
        }
        
        // load stores for core data
        let store = CoreDataInteractor.createAndLoadStores(name: "Stravify")
        ServiceLocator.shared.registerService(service: store)
        let context = store.newBackgroundContext()
        ServiceLocator.shared.registerService(service: context)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        let container: NSPersistentContainer = ServiceLocator.shared.getService()
        CoreDataInteractor.saveContext(container: container)
    }


}


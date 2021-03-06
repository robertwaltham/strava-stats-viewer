//
//  CoreDataInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-02.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import CoreData

/**
 Handles interactions with the Core Data stack (but not loading or saving individual objects) 
 */
class CoreDataInteractor {
    
    // Creates an NSPersistentContainer for the app session
    static func createAndLoadStores(name: String) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores() { storeDescription, error in
            guard error == nil else {
                let nserror = error! as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                
            }
        }
        return container
    }
    
    // Saves all contexts for container
    static func saveContext(container: NSPersistentContainer) {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // convenience function to return a JSONDecoder with a new background context passed in
    static func JSONDecoderWithContext() -> JSONDecoder {
        let context: NSManagedObjectContext = ServiceLocator.shared.getService()

        let decoder = JSONDecoder()
        decoder.userInfo = [CodingUserInfoKey.context! : context]

        return decoder
    }
    
}

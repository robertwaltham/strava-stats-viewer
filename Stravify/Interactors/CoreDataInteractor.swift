//
//  CoreDataInteractor.swift
//  Stravify
//
//  Created by Robert Waltham on 2018-03-02.
//  Copyright © 2018 Robert Waltham. All rights reserved.
//

import Foundation
import CoreData

class CoreDataInteractor {
    
    static func createAndLoadStores(name: String) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores() { storeDescription, error in
            guard error != nil else {
                let nserror = error! as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                
            }
        }
        return container
    }
    
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
    
}

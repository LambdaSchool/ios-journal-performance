//
//  CoreDataStack.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "JournalCoreData" as String)
        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        /// This is required for the viewContext (ie. the main context) to be updated with changes saved in a background context. In this case, the viewContext's parent is the persistent store coordinator, not another context. This will ensure that the viewContext gets the changes you made on a background context so the fetched results controller can see those changes and update the table view automatically.
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()
    
    var mainContext: NSManagedObjectContext { return container.viewContext }
}

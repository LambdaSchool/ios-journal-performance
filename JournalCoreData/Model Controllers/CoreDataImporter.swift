//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        // This right here.
        // fetch request. then predicate IN one of the constants that hold the array of IDs
        
        self.context.perform {
            // do catch block in here on used on fetch
            // do update existing entries
            // check to see if its a new entry and if not create a new one.
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
//                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
            }
            completion(nil)
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    //var cacheDict: Dictionary< String: JSON > = [:]
    
   
    
    let context: NSManagedObjectContext
    private let cache = Cache<Int, Data>()
}

// We could Cache the items from CoreData
// Prevent redudant fetch requests

// get the entries with id stores them in a constant and filters them with compact map do that with the identifier as well.
// stores them in the constants. Then create dictionary use those constants as the Value : Key init on dictionary uniqueKeysWithValues
// entries to create and set it to the dictionary.
// then does fetch request

// Do one fetch request and put the results in a Dictionary cache. Instead of doing the predicate on the fetchrequest have it search the dictionary instead.
// create the cache like before. In the completion of the fetch request have those items use the add items to cache funciton.
// Create a function to search through the dictionary and do what the fetchSingleEntryFromPersistentStore function was doing.

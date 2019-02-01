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
    
    func sync(entryRepresentations: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest() // create an Entry NSFetchRequest
            var result: [Entry]? = nil // create an entry array named 'result' that will store the entries you find in the Persistent Store
            
            do { // in the current (background) context, perform the fetch request from the persistent store
                result = try self.context.fetch(fetchRequest) // assign the (error-throwing) fetch request, done on the background context, to result
            } catch {
                NSLog("Error fetching list of entries: \(error)") // if the fetch request throws an error, NSLog it
            }
            
            // we now need to check to see that we have results back
            // if we do, let's create a dictionary to put those results in
            
            if let alreadyInCoreDataEntries = result {
                var coreDataDictionary: [String: Entry] = [:] // if there is already a list of arrays in core data, make a dictionary
                
                for existingEntry in alreadyInCoreDataEntries {
                    guard let identifier = existingEntry.identifier else { return }
                    coreDataDictionary[identifier] = existingEntry
                }
                
                for entryRep in entryRepresentations {
                    guard let identifier = entryRep.identifier else { return }
                    
                    if let entry = coreDataDictionary[identifier], entry != entryRep {
                        self.update(entry: entry, with: entryRep)
                    } else if coreDataDictionary[identifier] == nil {
                        _ = Entry(entryRepresentation: entryRep, context: self.context)
                    }
                    
                }
                
            } else {
                // the fetch request returned no results, meaning there was nothing in core data,
                // meaning all we have to do is just create new entries from each entry representation
                
                for entryRep in entryRepresentations {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
                
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

    let context: NSManagedObjectContext
}

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
        
        self.context.perform {
            
            // creating an Entry NSFetchRequest
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            
            // create an entry array named 'result' that will store the entries you find
            // in the Persistent Store
            var result: [Entry]? = nil
            
            // in the current (background) context, perform the fetch request from the persistent store
            do {
                // assign the (error-throwing) fetch request, done on the background context, to the
                // value result
                result = try self.context.fetch(fetchRequest)
            } catch {
                // if the fetch request throws an error, NSLog it
                NSLog("Error fetching list of entries: \(error)")
            }
            
            // if there is already a list of arrays in core data,
            if let alreadyInCoreDataEntries = result/*, entry != entryRep*/ {
                
                for existingEntry in alreadyInCoreDataEntries {
                    
                }
                
                // update the entry with
                
                self.update(entry: entry, with: entryRep)
            } else if result == nil {
                _ = Entry(entryRepresentation: entryRep, context: self.context)
            }
            
            // for each entry in the MASSIVE array of entries (10,000 long)
            for entryRep in entries {
                
                // safely unwrap the specific entryRep identifier
                guard let identifier = entryRep.identifier else { continue }
                
                // creating an NSPredicate that looks for a matching identifier in the persistent store
                fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifier)
            
            }
            
            }
            
            //                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
            
            
            
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
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
//
//        // getting the optional(indentifer) that was passed
//        guard let identifier = identifier else { return nil }
//
//        // creating an Entry NSFetchRequest
//        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
//        // creating an NSPredicate that looks for a matching identifier in the persistent store
//        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
//
//        // create a entry and assign it to nil
//        var result: Entry? = nil
//
//        // in the current (background) context, perform
//        do {
//            result = try context.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }

    let context: NSManagedObjectContext
}

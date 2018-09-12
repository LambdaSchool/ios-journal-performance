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
        
        print("Started syncing")
        
        self.context.perform {
//            for entryRep in entries {
//                guard let identifier = entryRep.identifier else { continue }
//
//                /* Go through and compare the entry to the entry in core data one at a time using identifier. Since we're in a loop, we are comparing the entry # of times (however many entries there are).
//                 This way is very inefficient, because if there are 10,000 entries, we are looping through and calling fetchSingleEntryFromPersistentStore 10,000 times! Total 10,000 x 10,000 times
//                 */
//                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
//            }
            
            var identifiersFromServer: [String] = []
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                identifiersFromServer.append(identifier)
            } // 10,000 times
            
            let coreDataEntries = self.fetchEntriesFromPersistentStore(with: identifiersFromServer, in: self.context)
            
            /*
             At this point, we're going to need to loop through all the entries from the server one more time. The naive thing to do would be to loop through all the core data entries searching for an entry in common for every entry from the server. This means we would be looping at worst 10,000 X 10,000 times, which is a lot! We're not going to do this!!!
             */
            
            // Look up table using a dictionary to make it fast, but it will use up more memory.
            var coreDataEntryLookupTable: [String : Entry] = [:]
            
            if let coreDataEntries = coreDataEntries {
                for entry in coreDataEntries {
                    guard let identifier = entry.identifier else { continue }
                    
                    // adding this entry to the lookup table at that identifier. if an entry doesn't have an identifier, we dont care to add it.
                    coreDataEntryLookupTable[identifier] = entry
                } // 10,000 times max, b/c there might be nothing in there
            }
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let coreDataEntry = coreDataEntryLookupTable[identifier]
                if let coreDataEntry = coreDataEntry, coreDataEntry != entryRep {
                    self.update(entry: coreDataEntry, with: entryRep)
                } else if coreDataEntry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            } // 10,000 times
            
            print("Finished syncing")
            
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry]? {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        do {
            return try context.fetch(fetchRequest) // success return array
        } catch {
            NSLog("Error fetching entries from core data: \(error)")
        }
        
        return nil // otherwise, return nil
    }
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
//
//        guard let identifier = identifier else { return nil }
//
//        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
//        // this predicate is telling core data how to find the entry with the given identifier, checking one entry at a time
//        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
//
//        /*If merging firebase and care data wasn't done correctly there could be duplicates of the same entry, and we could have multiple entries with the same identifier.
//         */
//
//        var result: Entry? = nil
//        do {
//            result = try context.fetch(fetchRequest).first // actually doing the search and getting the first out of the array. By calling .first, we conveniently get the only entry in the array.
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }
    
    let context: NSManagedObjectContext
}

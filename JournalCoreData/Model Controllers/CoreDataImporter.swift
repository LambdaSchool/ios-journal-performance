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
        
        let start = CFAbsoluteTimeGetCurrent()
        let localStoreEntries = fetchEntriesFromPersistentStore(entries: entries, context: self.context)
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let entry = localStoreEntries[identifier]
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            let end = CFAbsoluteTimeGetCurrent() - start
            // Add print statement after syncing finishes
            print("Syncing complete. Time: \(end) seconds")
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
    
    private func fetchEntriesFromPersistentStore(entries: [EntryRepresentation], context: NSManagedObjectContext) -> [String: Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let identifiers: [String] = entries.compactMap { $0.identifier }
        // Fetch request predicates can use the `IN` operator to check for a value in an array. e.g. `NSPredicate("identifier IN %@", arrayOfIdentifiers)`.
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        // set up values as a dictionary for more performant code (at cost to memory)
        var result: [String: Entry] = [:]
        
        do {
            let fetchedEntries = try context.fetch(fetchRequest)
            
            for entry in fetchedEntries {
                result[entry.identifier!] = entry
            }
        }
        catch {
            NSLog("Error fetching entries: \(error)")
        }
        
        return result
        
        
    }
    
    
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
//
//        guard let identifier = identifier else { return nil }
//
//        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
//
//        var result: Entry? = nil
//        do {
//            result = try context.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }
    
    let context: NSManagedObjectContext
}

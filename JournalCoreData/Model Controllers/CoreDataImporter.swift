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
        
        print("Syncing")
        let localStoreEntries = fetchEntriesFromPersistentStore(entries: entries, context: self.context)
        
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                //takes a long time      //should be fixed
                let entry = localStoreEntries[identifier]
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            print("Done syncing")
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
    
    // fixes issues with single fetch function
    private func fetchEntriesFromPersistentStore(entries: [EntryRepresentation], context: NSManagedObjectContext) -> [String : Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let identifiers: [String] = entries.compactMap { $0.identifier }
        
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var result: [String : Entry] = [:]
        
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
//        // warning here  // Should be fixed
//        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", [identifier])
//
//        var result: Entry? = nil
//        do {
//            //Hangup here
//            result = try context.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }
    
    let context: NSManagedObjectContext
}

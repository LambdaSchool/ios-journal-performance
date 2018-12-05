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
            NSLog("loading \(entries.count) entries")
            let cachedEntries = self.fetchSingleEntryFromPersistentStore(with: entries, in: self.context)
            NSLog("loaded \(cachedEntries.count) entries")
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                guard let entry = cachedEntries[identifier] else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                    continue
                }
                if entry != entryRep {
                    self.update(entry: entry, with: entryRep)
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
    
    private func fetchSingleEntryFromPersistentStore(with identifiers: [EntryRepresentation], in context: NSManagedObjectContext) -> [String:Entry] {
        
        // guard let identifiers = identifiers else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let identifiers: [String] = identifiers.compactMap {$0.identifier}
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results = [String:Entry]()
        do {
            let entries = try context.fetch(fetchRequest)
            for entry in entries {
                results[entry.identifier!] = entry
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return results
    }
    
    let context: NSManagedObjectContext
}


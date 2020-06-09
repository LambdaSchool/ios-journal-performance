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
    // issues
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        self.context.perform {
            let identifiers = entries.compactMap ({ $0.identifier })
            let myEntries = self.fetchEntriesFromPersistentStore(with: identifiers, in: self.context)
            
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                if let entry = myEntries[identifier] {
                    self.update(entry: entry, with: entryRep)
                } else {
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
    // This is where most changes need to happen. Slow.
    // Changed from single entry to all since it was not populating all my entries, loading circle of death
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [String : Entry] {
        
        //        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        // changed
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var result = [String : Entry]()
        do {
            result = try context.fetch(fetchRequest).reduce(into: [String : Entry]()) {
                // $1 represents the second parameter, $0 is the first parameter
                guard let id = $1.identifier else { return }
                $0[id] = $1
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
    
}

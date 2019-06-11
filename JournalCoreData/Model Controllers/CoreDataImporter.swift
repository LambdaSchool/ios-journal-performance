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
            
            var entriesFromServer = entries
            let identifiers = entries.compactMap { $0.identifier }
            
            let entriesFromPersistentStore = self.fetchSingleEntryFromPersistentStore(with: identifiers, in: self.context)
            guard let entriesFromPersistent = entriesFromPersistentStore else { return }
            
            for (index, entryRep) in entries.enumerated() {
                
                for entryFromPersistent in entriesFromPersistent {
                    
                    if entryRep.identifier == entryFromPersistent.identifier {
                        self.update(entry: entryFromPersistent, with: entryRep)
                        entriesFromServer.remove(at: index)
                    }
                }
            }
            
            for entry in entriesFromServer {
                _ = Entry(entryRepresentation: entry, context: self.context)
            }
            
            
            // MARK: - Time for performance testing
            let time = Date()
            let timeFomat = DateFormatter()
            timeFomat.dateFormat = "HH:mm:ss"
            print("Time Ended: \(timeFomat.string(from: time))")
            // MARK: - END
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
    
    private func fetchSingleEntryFromPersistentStore(with identifiers: [String]?, in context: NSManagedObjectContext) -> [Entry]? {
        
        guard let identifiers = identifiers else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results: [Entry]? = nil
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return results
    }
    
    let context: NSManagedObjectContext
}

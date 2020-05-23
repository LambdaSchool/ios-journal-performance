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
    
    func sync(entries: [String: EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            let coreEntries = self.fetchEntriesFromPersistentStore(in: self.context)
            guard let coreEntriesUW = coreEntries else { return }
            
            print("Started sync \(Date())")
            
            for (id, entryRep) in entries {
                //guard let identifier = entryRep.identifier else { continue }
                let entry = coreEntriesUW[id]
                if let entry = entry, entryRep != entry {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            self.coreCache = entries
            
            print("Finished sync \(Date())")
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
    
    private func fetchEntriesFromPersistentStore(in context: NSManagedObjectContext) -> [String : Entry]? {

        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()

        var result: [Entry]? = nil

        do {
            result = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries from server")
        }

        guard let results = result else { return nil }
        var entriesByID: [String: Entry] = [:]
        for entry in results {
            if let id = entry.identifier {
                entriesByID[id] = entry
            }
        }

        return entriesByID
    }
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
    var coreCache: [String : EntryRepresentation] = [:]
}

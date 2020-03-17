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
        print("began syncing")
        let start = CFAbsoluteTimeGetCurrent()
        self.context.perform {
            
            let idsToFetch = entries.compactMap { $0.identifier }
            self.fetchEntriesByIDs(ids: idsToFetch, in: self.context)
//            let entriesToUpdate = self.fetchEntrysFromPersistentStore(with: idsToFetch, in: self.context)
            
//            if let entriesToUpdate = entriesToUpdate {
//                for entry in entriesToUpdate {
//                    self.update(entry: entry, with: entryRep)
//                }
//            }
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }

                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
            print("completed syncing")
            let end = CFAbsoluteTimeGetCurrent()
            print("took: \(end - start) seconds to sync")
        }
        
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchEntriesByIDs(ids: [String], in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", ids)
        
        var results: [Entry] = []
        do {
            results = try context.fetch(fetchRequest)
            for result in results {
                entries[result.identifier!] = result
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
    
    }
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
    
        var result: Entry? = nil
        result = entries[identifier]
        return result
    }
    
    let context: NSManagedObjectContext
    var entries: [String: Entry] = [:]
}

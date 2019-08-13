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
            let entryIdentifiers = entries.map({$0.identifier})
            var entryDict = Dictionary(uniqueKeysWithValues: zip(entryIdentifiers, entries))
            let entriesToUpdate = self.fetchEntriesFromPersistentStore(with: entryIdentifiers, in: self.context)
            
            for entry in entriesToUpdate {
                if let entryRep = entryDict[entry.identifier], entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                }
                
                entryDict.removeValue(forKey: entry.identifier)
            }
            
            for entryRep in entryDict.values {
                _ = Entry(entryRepresentation: entryRep, context: self.context)
            }
            
//            for entryRep in entries {
//                guard let identifier = entryRep.identifier else { continue }
//
//                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
//            }
            
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String?], in context: NSManagedObjectContext) -> [Entry] {
        
//        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results: [Entry] = []
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return results
    }
    
    let context: NSManagedObjectContext
}

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
            
            let fetchEntries = entries.compactMap { $0.identifier }
            let representationsByID = Dictionary(uniqueKeysWithValues: zip(fetchEntries, entries))
            var entriesToCreate = representationsByID
            
            let entriesToFetch = self.fetchEntriesFromServer(with: fetchEntries, in: self.context)
            
            for entry in entriesToFetch {
                guard let id = entry.identifier,
                let representation = representationsByID[id] else { continue }
                
                if entry != representation {
                    self.update(entry: entry, with: representation)
                }
                entriesToCreate.removeValue(forKey: id)
            }
            
            for representation in entriesToCreate.values {
            _ =    Entry(entryRepresentation: representation, context: self.context)
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
    
    private func fetchEntriesFromServer(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifiers)
        
        var result: [Entry] = []
        
        do {
            result = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries: \(error)")
        }
        
        return result
    }
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        
        do {
            // detected the issue
            result = try context.fetch(fetchRequest).first
            
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        
        return result
    }
    
    
    let context: NSManagedObjectContext
}

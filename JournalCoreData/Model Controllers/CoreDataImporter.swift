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
        let representationsWithID = entries.filter { $0.identifier != nil }
        let identifiersToFetch = representationsWithID.compactMap { $0.identifier! }
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representationsWithID))
        var entriesToCreate = representationsByID
        
        self.context.perform {
            guard let coreDataEntries = self.fetchEntriesFromPersistentStore(with: identifiersToFetch, in: self.context) else {
                completion(NSError())
                return
            }
            
            // Update existing Core Data Entries
            for entry in coreDataEntries {
                guard let identifier = entry.identifier,
                    let entryRep = representationsByID[identifier] else { continue }
                
                if entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                }
                entriesToCreate.removeValue(forKey: identifier)
            }
            
            // Create new Entries in Core Data
            for entryRep in entriesToCreate.values {
                _ = Entry(entryRepresentation: entryRep, context: self.context)
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
    
    /*
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
    */
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String]?, in context: NSManagedObjectContext) -> [Entry]? {
        
        guard let identifiers = identifiers else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results: [Entry]? = nil
        do {
            results = try context.fetch(fetchRequest)
            if results == nil { results = [] }
        } catch {
            NSLog("Error fetching all entries: \(error)")
        }
        return results
    }
    
    let context: NSManagedObjectContext
}

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
            var identifiersToFetch: [String] = []
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                identifiersToFetch.append(identifier)
            }
            
            if let fetchedEntries = self.fetchEntriesFromPersistentStore(with: identifiersToFetch, in: self.context) {
                for entryRep in entries {
                    guard let identifier = entryRep.identifier else { continue }

                    let entry = fetchedEntries.first(where: { $0.identifier == identifier })
                    if let entry = entry, entry != entryRep {
                        self.update(entry: entry, with: entryRep)
                    } else if entry == nil {
                        _ = Entry(entryRepresentation: entryRep, context: self.context)
                    }
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry]? {
                
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var result: [Entry]? = nil
        do {
            result = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

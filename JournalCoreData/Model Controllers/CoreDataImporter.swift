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
    
    func sync(entryReps: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            var repIdentifiers: [String] = []
            var entryRepsByIdentifier: [String: EntryRepresentation] = [:]
            
            for entryRep in entryReps {
                guard let identifier = entryRep.identifier else { continue }
                
                repIdentifiers.append(identifier)
                entryRepsByIdentifier[identifier] = entryRep
            }
            
            let localEntries = self.fetchEntriesFromPersistentStore(with: repIdentifiers, in: self.context)
            
            let localIds = localEntries.compactMap { $0.identifier }
            let localEntriesByIdentifier = Dictionary(uniqueKeysWithValues:
                zip(localIds, localEntries)
            )
            for entryRep in entryReps {
                guard let repId = entryRep.identifier else { fatalError() }
                
                if let localEntry = localEntriesByIdentifier[repId] {
                    if localEntry != entryRep {
                        self.update(entry: localEntry, with: entryRep)
                    }
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry] {
        
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

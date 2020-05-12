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
        let identifiersToFetch = entries.compactMap { $0.identifier }
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entries))
        var entriesToCreate = representationsByID
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        self.context.perform {
            do {
                let existingEntries = try self.context.fetch(fetchRequest)
                
                for entry in existingEntries {
                    guard let id = entry.identifier,
                        let entryRep = representationsByID[id] else { continue }
                    
                    self.update(entry: entry, with: entryRep)
                    entriesToCreate.removeValue(forKey: id)
                }
                
                for entryRep in entriesToCreate.values {
                    Entry(entryRepresentation: entryRep, context: self.context)
                }
                                
                try self.context.save()
            } catch {
                NSLog("Failed to fetch entries.")
                return completion(error)
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
    
    let context: NSManagedObjectContext
}

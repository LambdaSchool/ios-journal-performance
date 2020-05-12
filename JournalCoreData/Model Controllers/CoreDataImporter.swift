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
        
        let entriesWithId = entries.filter { $0.identifier != nil }
        let indentifiersToFetch = entriesWithId.compactMap {$0.identifier! }
        
        let representatoinById = Dictionary(uniqueKeysWithValues: zip(indentifiersToFetch, entriesWithId))
        
        var entriesToCreate = representatoinById
        
        // Hint 1: Fetch request predicates can use the `IN` operator to check for a value in an array. e.g. `NSPredicate("identifier IN %@", arrayOfIdentifiers)`.
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", indentifiersToFetch)
        
        self.context.perform {
            do {
                let existingEntries = try self.context.fetch(fetchRequest)
                
                for entry in existingEntries {
                    guard let id = entry.identifier,
                        let representation = representatoinById[id] else { continue }
                    
                    self.update(entry: entry, with: representation)
                    entriesToCreate.removeValue(forKey: id)
                }
                
                for representatoin in entriesToCreate.values {
                    _ = Entry(entryRepresentation: representatoin, context: self.context)
                }
                print("Syncing Complete")
                completion(nil)
            } catch {
                print("Error fetching entries with identifiers: \(error)")
            }
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
    
    let context: NSManagedObjectContext
}

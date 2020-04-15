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
        
        /// Perform the fetch request on your core data stack's mainContext.
        //let context = CoreDataStack.shared.container.newBackgroundContext()
        
        self.context.perform {
            /// Create a dictionary with the identifiers of the representations as the keys, and the values as the representations. To accomplish making this dictionary you will need to create a separate array of just the entry representations identifiers. You can use the zip method to combine two arrays of items together into a dictionary.
            let identifiersToFetch = entries.compactMap { $0.identifier }
            let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entries))
            var entriesToCreate = representationsByID

            let entriesFromServer = self.fetchEntriesFromPersistentStore(with: identifiersToFetch, in: self.context)

            /// Loop through the fetched entries and call update. Then remove the entry from the dictionary. Afterwards we'll create entries from the remaining objects in the dictionary. The only ones that would remain after this loop are ones that didn't exist in Core Data already.
            for entry in entriesFromServer {
                guard let id = entry.identifier,
                    let representation = representationsByID[id] else { continue }
                // FIXME: Remove this test for not equal for horrible performace.
                if entry != representation {
                    self.update(entry: entry, with: representation)
                }
                entriesToCreate.removeValue(forKey: id)
            }
            
            /// Create an entry for each of the values in entriesToCreate using the Entry initializer that takes in an EntryRepresentation and an NSManagedObjectContext
            for representation in entriesToCreate.values {
                _ = Entry(entryRepresentation: representation, context: self.context)
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
        fetchRequest.predicate = NSPredicate(format: "identifier in %@", identifiers)
        
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
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

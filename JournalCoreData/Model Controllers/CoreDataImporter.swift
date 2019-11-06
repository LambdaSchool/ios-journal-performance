//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            let start = CACurrentMediaTime()

            let identifiersToFetch = entries.map({ $0.identifier })
            let representationByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entries))
            var entryToCreate = representationByID
            let entries = self.fetchEntriesFromPersistentStore(with: identifiersToFetch, in: self.context)
            
            for entryRep in entries {
                guard let entryRep = entryRep,
                        let identifier = entryRep.identifier,
                        let representation = representationByID[identifier] else { continue }
                self.update(entry: entryRep, with: representation)
                entryToCreate.removeValue(forKey: identifier)
            }
            
            for representation in entryToCreate.values {
                _ = Entry(entryRepresentation: representation, context: self.context)
            }
            print("\(CACurrentMediaTime() - start) to complete sync method")
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String?], in context: NSManagedObjectContext) -> [Entry?] {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results: [Entry?] = [nil]
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries: \(error)")
        }
        return results
    }
    
    let context: NSManagedObjectContext
}

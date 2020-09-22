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
    
    func sync(with representations: [EntryRepresentation]) throws {
        let context = CoreDataStack.shared.container.newBackgroundContext()
        let identifiersToFetch = representations.compactMap({ $0.identifier })
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        var entriesToCreate = representationsByID
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        context.performAndWait {
            do {
                let existingEntries = try context.fetch(fetchRequest)
                for entry in existingEntries {
                    guard let id = entry.identifier,
                        let representation = representationsByID[id] else {
                            continue }
                    
                    update(entry: entry, with: representation)
                    
                    entriesToCreate.removeValue(forKey: id)
                }
                for representation in entriesToCreate.values {
                    Entry(entryRepresentation: representation, context: context)
                }
            } catch {
                print("Error fetching entries for UUIDs: \(error)")
            }
        }
        try CoreDataStack.shared.save(context: context)
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
    }

}

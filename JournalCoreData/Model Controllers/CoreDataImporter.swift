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
    let context: NSManagedObjectContext
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        print("Starting sync")

        let identifiersToFetch = entries.compactMap({ ($0.identifier) })

        let representationsByID = Dictionary(uniqueKeysWithValues:
            zip(identifiersToFetch, entries)
        )

        var entriesToCreate = representationsByID
        let predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)

        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = predicate

        self.context.performAndWait {
            do {
                let existingEntries = try self.context.fetch(fetchRequest)

                for entryReps in existingEntries {
                    guard let id = entryReps.identifier, let entryRep = representationsByID[id] else { continue }
                    self.update(entry: entryReps, with: entryRep)
                    entriesToCreate.removeValue(forKey: id)
                }

                for nilEntries in entriesToCreate.values {
                    Entry(entryRepresentation: nilEntries, context: self.context)
                }

            } catch {
                NSLog("Error fetching entries for identifiers: \(error)")
                completion(nil)
            }
            do {
                try CoreDataStack.shared.save(context: self.context)
            } catch {
                print("error saving)")
            }
            self.context.reset()
        }
    }

    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
}


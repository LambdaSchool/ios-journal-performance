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

        let entriesToFetch = entries.compactMap  { $0.identifier }
        let entriesByID = Dictionary(uniqueKeysWithValues: zip(entriesToFetch, entries))
        var entriesToCreate = entriesByID
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", entriesToFetch)

        let context = CoreDataStack.shared.container.newBackgroundContext()

          context.perform {
                do {
                    let existingEntries = try context.fetch(fetchRequest)
                    for entry in existingEntries {
                        guard let identifier = entry.identifier,
                            let representation = entriesByID[identifier] else { continue }
                        self.update(entry: entry, with: representation)
                        entriesToCreate.removeValue(forKey: identifier)
                    }

                    for entry in entriesToCreate.values {
                        Entry(entryRepresentation: entry, context: context)
                    }
                    try context.save()
                } catch {
                    NSLog("error fetching entries with IDs: \(entriesToFetch), with error: \(error)")
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

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


        let identifiers = entries.compactMap { $0.identifier }
        let fetchEntries = Dictionary(uniqueKeysWithValues: zip(identifiers, entries))
        var entriesToCreate = fetchEntries
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)

        let context = CoreDataStack.shared.container.newBackgroundContext()

        context.perform {

            do {
                let existingEntries = try context.fetch(fetchRequest)
                for entry in existingEntries {
                    guard let identifier = entry.identifier,
                        let representation = fetchEntries[identifier] else { continue }
                    self.update(entry: entry, with: representation)
                    entriesToCreate.removeValue(forKey: identifier)
                }

                for entry in entriesToCreate.values {
                    Entry(entryRepresentation: entry, context: context)
                }
                try context.save()
            } catch {
                NSLog("error fetching entries with IDs: \(identifiers) error: \(error)")

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

    let context: NSManagedObjectContext
}

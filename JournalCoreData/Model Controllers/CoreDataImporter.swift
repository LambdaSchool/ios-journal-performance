
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

        print("sync started: \(Date())")
        let identifiers: [String] = entries.compactMap { ($0.identifier) }
        let entry = self.fetchSingleEntryFromPersistentStore(identifiers: identifiers, in: self.context)

        self.context.perform {



            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }

                let entry = entry![identifier]
                if let entry = entry, entry != entryRep {
                    // update to Firebase & Core Data
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
            print("sync finished: \(Date())")
        }
    }

    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }

    private func fetchSingleEntryFromPersistentStore(identifiers: [String], in context: NSManagedObjectContext) -> [String: Entry]? {


        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)

        var result: [String: Entry] = [:]
        do {
            let results = try context.fetch(fetchRequest)
            for entry in results {
                result[entry.identifier!] = entry
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }


    let context: NSManagedObjectContext
}

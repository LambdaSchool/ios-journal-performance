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

    var cachedEntries: [String : EntryRepresentation] = [:]

    func sync(entries: [String: EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {

            print(" Sync initialized \(Date())")

            let journalEntries = self.fetchEntriesFromPersistenStore(in: self.context)
            guard let unwrappedJournalEntries = journalEntries else { return }


            for (id, entryRep) in entries {
                let entry = unwrappedJournalEntries[id]
                if let entry = entry, entryRep != entry {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }

            self.cachedEntries = entries
        }
        print ("Sync complete \(Date())")
        // Initial run sync time 2+ minutes  , final time no difference
        completion(nil)
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

    private func fetchEntriesFromPersistenStore(in conterxt: NSManagedObjectContext) -> [String: Entry]? {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()

        var results: [Entry]? = nil

        do {
            results = try context.fetch(request)
        } catch {
            NSLog("Error fetching results \(error)")
        }


        guard let resultArray = results else { return nil }
        var entryArray: [String: Entry] = [:]
        for entry in resultArray {
            if let id = entry.identifier {
                entryArray[id] = entry
            }
        }
        return entryArray
    }



    let context: NSManagedObjectContext
}

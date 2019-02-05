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
        print("Started")
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let entry = self.fetchSingleEntryFromPersistentStore(with: [identifier], in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            print("Finished")
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
    
    private func fetchSingleEntryFromPersistentStore(with identifiers: [String]?, in context: NSManagedObjectContext) -> [String: Entry]? {
        
        guard let identifier = identifiers else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifier)
        
        var results: [Entry] = []
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        var result: [String: Entry] = [:]
        for entry in results {
            result[entry.identifier!] = entry
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

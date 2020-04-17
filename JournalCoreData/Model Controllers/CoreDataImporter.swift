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
        
        let ids = entries.compactMap { $0.identifier }
               var repID = Dictionary(uniqueKeysWithValues: zip(ids, entries))
        
        self.context.perform{
            let MOCEntries = self.fetchEntries(with: ids, in: self.context)
            
            for entry in MOCEntries {
                guard let id = entry.identifier,
                    let rep = repID[id] else { return }
                self.update(entry: entry, with: rep)
                repID.removeValue(forKey: id)
            }
            for reps in repID.values {
                _ = Entry(entryRepresentation: reps, context: self.context)
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
    
    private func fetchEntries(with ids: [String], in context: NSManagedObjectContext) -> [Entry] {
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", ids)

             do {
                let entries = try context.fetch(fetchRequest)
                return entries
            } catch {
                NSLog("Error fetching: \(error)")
                return []
            }
        }

    let context: NSManagedObjectContext
}

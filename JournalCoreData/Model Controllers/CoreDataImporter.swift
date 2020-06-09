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
        let id = entries.compactMap { $0.identifier }
        var entrysByRep = Dictionary(uniqueKeysWithValues: zip(id, entries))
        
        self.context.perform {
            let existingEntries = self.fetchEntriesFromPersistentStore(with: id, in: self.context)
            
            for entry in existingEntries {
                guard let id = entry.identifier,
                    let representation = entrysByRep[id] else { continue }
                self.update(entry: entry, with: representation)
                entrysByRep.removeValue(forKey: id)
            }
        }
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        do {
            let entries = try context.fetch(fetchRequest)
            return entries
        } catch {
            NSLog("Error fetching entries: \(error)")
            return []
        }
    }
    
    let context: NSManagedObjectContext
}

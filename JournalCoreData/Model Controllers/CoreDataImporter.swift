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
        
        self.context.perform {
            print("Starting sync")
            let identifiers = entries.compactMap() { $0.identifier }
            let localEntries = self.fetchEntriesFromPersistentStore(with: identifiers, in: self.context)
            let divisions = entries.count > 100 ? entries.count / 20 : 1
            for (index, entryRep) in entries.enumerated() {
                if index % divisions == 0 {
                    let percentage = Float(index) / Float(entries.count)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateProgress"), object: nil, userInfo: ["progress" : percentage])
                }
                guard let identifier = entryRep.identifier else { continue }
                let entry = localEntries[identifier]
                //let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            print("Finished syncing")
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
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
//        
//        guard let identifier = identifier else { return nil }
//        
//        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
//        
//        var result: Entry? = nil
//        do {
//            result = try context.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [String : Entry] {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
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

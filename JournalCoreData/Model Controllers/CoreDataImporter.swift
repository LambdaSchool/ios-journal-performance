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
    
//    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
//        print("start syncing")
//        let localEntries = fetchSingleEntryFromPersistentStore(with: entries, in: self.context)
//        self.context.perform {
//            for entryRep in entries {
//                guard let identifier = entryRep.identifier else { continue }
//
//                let entry = localEntries[identifier]
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
//            }
//            print("start syncing")
//            completion(nil)
//        }
//    }
//
    
    
    
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        print("start syncing")

        self.context.perform {
            let entryStore = self.fetchSingleEntryFromPersistentStore(entries: entries, in: self.context)

            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }

               let entry = entryStore[identifier]
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            print("end syncing")
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
    
    private func fetchSingleEntryFromPersistentStore(entries:[EntryRepresentation] , in context: NSManagedObjectContext) -> [String: Entry] {
        
       // guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let identifiers: [String] = entries.compactMap {$0.identifier}
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        var result:[String: Entry] = [:]
        
       
        do {
           let entryFetching = try context.fetch(fetchRequest)
            for entry in entryFetching {
                result[entry.identifier!] = entry
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

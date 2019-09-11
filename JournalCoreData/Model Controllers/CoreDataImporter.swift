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
            var identifiers: [String] = []
            var existingEntriesDict: [String : Entry] = [:]
            
            
            for entryRep in entries {
                
                guard let identifier = entryRep.identifier else { continue }
                identifiers.append(identifier)
               
            }
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
            
            do {
                let existingEntries = try self.context.fetch(fetchRequest)
                for entry in existingEntries {
                    guard let identifier = entry.identifier else { continue }
                    existingEntriesDict[identifier] = entry
                }
            } catch {
                NSLog("Error fetching single entry: \(error)")
            }
            
            for entryRep in entries {
                if let identifier = entryRep.identifier, let entry = existingEntriesDict[identifier], entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if let identifier = entryRep.identifier, existingEntriesDict[identifier] == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
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
    
    let context: NSManagedObjectContext
}

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
    
    let context: NSManagedObjectContext
    let bgc: NSManagedObjectContext = CoreDataStack.shared.backgroundContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        var identifiersFromServer: [String] = []
        var entriesInCoreData: [String: Entry] = [:]
        
        self.bgc.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                identifiersFromServer.append(identifier)


            }
            let entriesFromCoreData = self.fetchEntriesFromPersistentStore(with: identifiersFromServer, in: self.bgc)
            
            for entry in entriesFromCoreData {
                // get entry.identifier
                guard let identifier = entry.identifier else { return }
                // set the key to that identifier and the value to that entry
                entriesInCoreData[identifier] = entry
            }
            
            for entryRep in entries {
                if let identifier = entryRep.identifier, let entry = entriesInCoreData[identifier], entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if let identifier = entryRep.identifier, entriesInCoreData[identifier] == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.bgc)
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var result: [Entry] = []
        
        do {
            result = try bgc.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries: \(error)")
        }
        return result
    }
}

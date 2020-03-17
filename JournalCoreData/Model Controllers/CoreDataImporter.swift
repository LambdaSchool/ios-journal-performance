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
    init(context: NSManagedObjectContext = CoreDataStack.shared.backgroundContext ) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
       
        print("Start syncing")
        self.context.perform {
            var identifiersFromServer: [String] = []
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                identifiersFromServer.append(identifier)
            }
                let coreDataEntries = self.fetchEntriesFromPersistentStore(with: identifiersFromServer, in: self.context)
            var coreDataEntryLookUpTable: [String: Entry] = [:]
            
            if let coreDataEntries = coreDataEntries {
                for entry in coreDataEntries {
                    guard let identifier = entry.identifier else { continue }
                    coreDataEntryLookUpTable[identifier] = entry
                }
            }
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let coreDataEntry = coreDataEntryLookUpTable[identifier]
                if let coreDataEntry = coreDataEntry, coreDataEntry != entryRep {
                    self.update(entry: coreDataEntry, with: entryRep)
                } else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            
            print("Finish syncing")
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
    
    private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry]? {
        
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
      
        do {
            
            let entries = try context.fetch(fetchRequest)
          return entries
     
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return nil
    }
    
    let context: NSManagedObjectContext
}

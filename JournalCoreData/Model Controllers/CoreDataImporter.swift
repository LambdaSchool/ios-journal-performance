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
            
            //Get All Entry Identifiers
            var entryRepIdentifiers: [String] = []
            for entryRep in entries {
                guard let identifier = entryRep.identifier else {
                    continue
                }
                entryRepIdentifiers.append(identifier)
                print(identifier)
            }
            
            //Fetch Entries
            var entry = self.fetchSingleEntryFromPersistentStore(with: entryRepIdentifiers, in: self.context)

            /*for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                //let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                if let entries = entry, entries != entryRep {
                    self.update(entry: entries , with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }*/
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
    
    private func fetchSingleEntryFromPersistentStore(with arrayOfIdentifiers: [String], in context: NSManagedObjectContext) -> [Entry?] {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", argumentArray: arrayOfIdentifiers as [Any])
        
        var result: [Entry?] = [nil]
        do {
            result = try context.fetch(fetchRequest)
            return result
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return [nil]
    }
    
    let context: NSManagedObjectContext
}

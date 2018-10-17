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
                print("start syncing")
                let identifiers = entries.compactMap{($0.identifier)}
                let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
                var entriesFromCoreData: [Entry] = []
                
                do {
                    entriesFromCoreData = try self.context.fetch(fetchRequest)
                } catch {
                    NSLog("Error fetching entries from core data: \(error)")
                }
                
                var dictionary = [String: Entry]()
                
                for entry in entriesFromCoreData {
                    dictionary[entry.identifier!] = entry
                }
                
                for entryRep in entries {
                    guard let identifier = entryRep.identifier else { continue }
                    
                    let entry = dictionary[identifier]
                    if let entry = entry, entry != entryRep {
                        self.update(entry: entry, with: entryRep)
                    } else if entry == nil {
                        _ = Entry(entryRepresentation: entryRep, context: self.context)
                    }
                    completion(nil)
                    if entries.count == 1 {
                        print("end syncing")
                    }
                }
                
            }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    let context: NSManagedObjectContext
}

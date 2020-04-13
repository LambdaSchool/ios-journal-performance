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
        print("Sync starts at", Date())
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let entry = self.fetchEntries(with: identifier, in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
            print("Sync ends at", Date())
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchEntries(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", [identifier])
        
        var result: Entry? = nil
        var resultDictionary: [String:Entry] = [:]
        
        do {
            let results = try context.fetch(fetchRequest)
            for entry in results {
                resultDictionary[entry.identifier!] = entry
                result = entry
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

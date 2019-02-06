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
        print("beginning sync")
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                let repIdentifiers: [String] = entries.compactMap { ( $0.identifier ) }
                
                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, from: repIdentifiers, in: self.context)
                    
                    if let entry = entry, entry != entryRep {
                        self.update(entry: entry, with: entryRep)
                    } else if entry == nil {
                        _ = Entry(entryRepresentation: entryRep, context: self.context)
                    }
              
            }
            print("done with sync")
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
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, from repIdentifiers: [String]?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        guard let repIdentifiers = repIdentifiers else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", repIdentifiers)
        
        var result: Entry? = nil
        
        var resultDict: [String: Entry] = [:]

            do {
                let results = try context.fetch(fetchRequest)
                for entry in results {
                   resultDict[entry.identifier!] = entry
                }
            } catch {
                NSLog("Error fetching single entry: \(error)")
            }
        
 
        return result
    }
    
    
    var context: NSManagedObjectContext
}

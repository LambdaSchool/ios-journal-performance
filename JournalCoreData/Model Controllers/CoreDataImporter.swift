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
        
        DispatchQueue.global().async {
            
            let entriesWithID = entries.filter { $0.identifier != nil }
            let identifiersToFetch = entriesWithID.compactMap {$0.identifier}
            let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entriesWithID))
            var entriesToCreate = representationsByID
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@",
                                                 argumentArray: identifiersToFetch)
            
            print("starting sync")
            
            self.context.perform {
                do{
                    let existingEntry = try self.context.fetch(fetchRequest)
                    
                    for entry in existingEntry{
                        guard let id = entry.identifier,
                            let representation = representationsByID[id] else { continue }
                        self.update(entry: entry,
                                    with: representation)
                        entriesToCreate.removeValue(forKey: id)
                    }
                    
                    for entry in entriesToCreate.values {
                        _ = Entry(entryRepresentation: entry,
                                  context: self.context)
                    }
                    completion(nil)
                } catch {
                    NSLog("Error fetching tasks for UUIDs: \(error)")
                    completion(error)
                }
                print("Completed sync")
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

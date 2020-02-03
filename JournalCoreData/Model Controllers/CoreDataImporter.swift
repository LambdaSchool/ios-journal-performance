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
            let entriesWithID = entries.filter { $0.identifier != nil}
            let identifiersToFetch = entriesWithID.compactMap { $0.identifier }
            
            let representationByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entriesWithID))
            
            var entriesToCreate = representationByID
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            //            let moc = CoreDataStack.shared.container.newBackgroundContext()
            
            self.context.perform {
                do {
                    let existingEntries = try self.context.fetch(fetchRequest)
                    
                    for entry in existingEntries {
                        guard let id = entry.identifier,
                            let representation = representationByID[id] else {
                                self.context.delete(entry)
                                continue
                        }
                        self.update(entry: entry, with: representation)
                        entriesToCreate.removeValue(forKey: id)
                    }
                    for representation in entriesToCreate.values {
                        Entry(entryRepresentation: representation, context: self.context)
                    }
                    completion(nil)
                } catch {
                    print("Error fetching tasks for identifiers: \(error)")
                    completion(error)
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

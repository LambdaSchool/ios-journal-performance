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
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    func updateEntries(with representations: [EntryRepresentation], completion: @escaping (Error?) -> () = {_ in}) {
        
        let entriesWithID = representations.filter({ $0.identifier != nil })
        
        let identifiersToFetch = entriesWithID.compactMap({ UUID(uuidString: $0.identifier!) })
        
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entriesWithID))
        
        var entriesToCreate = representationsByID
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        let context = CoreDataStack.shared.mainContext
        
        context.perform{
            
            do {
                let existingEntries = try context.fetch(fetchRequest)
                
                for entry in existingEntries {
                    guard let id = entry.identifier,
                        let identifier = UUID(uuidString: id),
                        let representation = representationsByID[identifier] else { continue }
                    self.update(entry: entry, with: representation)
                    
                    entriesToCreate.removeValue(forKey: identifier)
                }
                
                for representation in entriesToCreate.values {
                    _ = Entry(entryRepresentation: representation, context: context)
                }
                completion(nil)
            } catch {
                NSLog("Error fetching tasks for UUIDs: \(error)")
                completion(error)
            }
        }
    }
}

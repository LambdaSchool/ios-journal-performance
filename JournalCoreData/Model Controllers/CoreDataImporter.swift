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
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var count = 1
        print("Syncing: \(startTime)")
        
        self.context.perform {
            
            self.updateEntries(with: entries)
            completion(nil)
//            for entryRep in entries {
//                guard let identifier = entryRep.identifier else { continue }
//
//                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
//
////                print("Finish \(count): \(CFAbsoluteTimeGetCurrent() - startTime)")
//                count += 1
//            }
//            completion(nil)
            print("Finish \(count): \(CFAbsoluteTimeGetCurrent() - startTime)")
                            count += 1
        }
    }
    
    func updateEntries(with representations: [EntryRepresentation]) {
        
        // Which representations do we already have in Core Data?
        
        let identifiersToFetch = representations.map { $0.identifier }
        
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        
        // Make a mutable copy of the dictionary above
        
        var entriesToCreate = representationsByID
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        // Only fetch tasks with these identifiers
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch) // or potentially "identifier NOT IN %@"
        
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        context.performAndWait {
            
            
            
            do {
                let existingEntries = try context.fetch(fetchRequest)
                
                // Update the ones we do have
                
                for entry in existingEntries {
                    
                    // Grab the TaskRepresentation that corresponds to this task
                    guard let identifier = entry.identifier,
                        let representation = representationsByID[identifier] else { continue }
                    // This can be abstracted out to another function
                    entry.title = representation.title
                    entry.bodyText = representation.bodyText
                    entry.mood = representation.mood
                    
                    
                    entriesToCreate.removeValue(forKey: identifier)
                    
                }
                
                // Figure out which ones we don't have
                var entryCount = 1
                for representation in entriesToCreate.values {
                    Entry(entryRepresentation: representation, context: context)
                    entryCount += 1
                }
                try context.save()
                print("Created: \(entryCount) entries")
            } catch {
                print("Error fetching tasks from persistent store: \(error)")
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
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

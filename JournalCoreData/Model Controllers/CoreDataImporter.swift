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
    
    func sync(entriesDict: [String: EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        print("Sync starts \(Date())")
        
        let concurOp = BlockOperation {
            self.context.perform {
                let entryReps = entriesDict.compactMap({ $0.value })
                let identifiers = entriesDict.compactMap({ $0.key })
                    for entryRep in entryReps {
                        let entry = self.fetchSingleEntryFromPersistentStore(with: identifiers, in: self.context)
                        if let entry = entry, entry != entryRep {
                            self.update(entry: entry, with: entryRep)
                        } else if entry == nil {
                            _ = Entry(entryRepresentation: entryRep, context: self.context)
                        }
                    }
                
                print("Sync finished \(Date())")
                completion(nil)
            }
        }
        theQueue.addOperation(concurOp)
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchSingleEntryFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> Entry? {
        
//        guard let identifier = identifier else { return nil }
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers) // identifier IN %@, identifiers

        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
    let theQueue = OperationQueue() // Fetch entries concurrently
}

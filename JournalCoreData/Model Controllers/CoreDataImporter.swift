//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData
import QuartzCore

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                if let entry = entry, entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
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
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            //let start = CACurrentMediaTime()
            result = try context.fetch(fetchRequest).first
            //let end = CACurrentMediaTime()
            //print("time fething 1 request: \(end - start)") // ~ 0.03 seconds
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}

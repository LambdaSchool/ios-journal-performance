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
    
    // MARK: - Cache
    var cache: Cache<String, Entry>
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.cache = Cache<String, Entry>()
        populateCache { error in
            if let error = error {
                print("Oopsie error.")
            }
        }
        
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                if self.cache.value(for: identifier) == nil {
                    if let newEntry = Entry(entryRepresentation: entryRep, context: self.context) {
                        self.cache.cache(value: newEntry, for: identifier)
                    }
                } else {
                    let entry = self.cache.value(for: identifier)
                    if let entry = entry {
                        self.update(entry: entry, with: entryRep)
                    }
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
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?,in context: NSManagedObjectContext) -> Entry? {
        
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
    
    private func populateCache(completion: @escaping (Error?) -> Void) {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        // MARK: - CAUSE OF CRASH
        // This was the cause of the crash. Originally, I completely failed to realize CoreDataImporter operates with a BACKGROUND Context. So I had been usuing MAIN Context to populate cache which caused everything to lock up.
        let moc = self.context
        
        do {
            let request = try moc.fetch(fetchRequest)
            for entry in request {
                guard let identifier = entry.identifier else {
                    let error = NSError()
                    NSLog("Error unwrapping identifier from fetched entry")
                    completion(error)
                    return
                }
                cache.cache(value: entry, for: identifier)
            }
        } catch {
            NSLog("Error fetching core data Entries")
            completion(error)
            return
        }
    }
    
    let context: NSManagedObjectContext
}

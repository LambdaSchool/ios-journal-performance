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
            
        let entriesWithID = entries.map { $0.identifier }
        let entryIDs = Dictionary(uniqueKeysWithValues: zip(entriesWithID, entries))
        var entriesToCreate = entryIDs
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", entriesWithID)
        
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        
            
            print("started sync: \(Date())")
                do {
                    let exsistingEntries = try context.fetch(fetchRequest)
                    for entry in exsistingEntries {
                        guard let id = entry.identifier,
                            let representation = entryIDs[id] else { continue }
                        self.update(entry: entry, with: representation)
                        entriesToCreate.removeValue(forKey: id)
                    }
                    for representation in entriesToCreate.values {
                        Entry(entryRepresentation: representation, context: context)
                    }
                } catch {
                    print("Error fetching Entry from persistant Store: \(error)")
                }
                
                do {
                    try context.save()
                } catch {
                    print("Error saving to database: \(error)")
                }
            
            print("finished syncing: \(Date())")
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
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifier)
        
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

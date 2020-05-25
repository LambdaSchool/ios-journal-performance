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
    
    // MARK: - Properties
    
    let context: NSManagedObjectContext
    var coreDataDictionary : [String : EntryRepresentation] = [:]
    
    // MARK: - Methods
    func sync(entries: [String : EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            let startDate = Date()
            guard let entriesInCoreData = self.fetchEntriesFromPersistentStore(in: self.context) else { return }
                
                // This is it folks
            for (id, entryRep) in entries {
                let entry = entriesInCoreData[id]
                if let entry = entry,
                    entry != entryRep {
                    self.update(entry: entry, with: entryRep)
                } else if entry == nil {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            
            self.coreDataDictionary = entries
            let finishedDate = Date()
            print("sync time: \(finishedDate.timeIntervalSince(startDate))")
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
    
    private func fetchEntriesFromPersistentStore(in context: NSManagedObjectContext) -> [String : Entry]? {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        
        var result: [Entry]?
        
        do {
            result = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching entries from persistent store \(error)")
        }
        guard let unwrappedResult = result else { return nil }
        var entriesById : [String : Entry] = [:]
        
        unwrappedResult.forEach { entry in
            if let id = entry.identifier {
                entriesById[id] = entry
            }
        }
        
        return entriesById
    }
    
    //    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
    //
    //        guard let identifier = identifier else { return nil }
    //
    //        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    //        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
    //
    //        var result: Entry? = nil
    //        do {
    //            result = try context.fetch(fetchRequest).first
    //        } catch {
    //            NSLog("Error fetching single entry: \(error)")
    //        }
    //        return result
    //    }
    
    
}

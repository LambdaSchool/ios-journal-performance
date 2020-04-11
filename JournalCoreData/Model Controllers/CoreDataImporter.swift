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
//    init(context: NSManagedObjectContext) {
    init(context: NSManagedObjectContext = CoreDataStack.shared.backgroundContext) {
        
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        // check syncing time manually
        print("begin Syncing")
        let beginTime = CFAbsoluteTimeGetCurrent()

        self.context.perform {
            
            // creat empty array of sting IDs
             var idFromServer: [String] = []
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                //append list of id to empty array
                idFromServer.append(identifier)
                  }
            
            let coreDataEntries = self.fetchAllEntriesFromPersistentStore(with: idFromServer, in: self.context)
            var coreDataEntryTableLookup: [String: Entry] = [:]
            
            if let coreDataEntries = coreDataEntries {
                for entry in coreDataEntries {
                    guard let identifier = entry.identifier else { continue }
                    coreDataEntryTableLookup[identifier] = entry
                }
                }
            
//                let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
//                if let entry = entry, entry != entryRep {
//                    self.update(entry: entry, with: entryRep)
//                } else if entry == nil {
//                    _ = Entry(entryRepresentation: entryRep, context: self.context)
//                }
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                let coreDataEntry = coreDataEntryTableLookup[identifier]
                if let coreDataEntry = coreDataEntry, coreDataEntry != entryRep {
                    self.update(entry: coreDataEntry, with: entryRep)
                } else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
            print("Syncing completed")
            let endTime = CFAbsoluteTimeGetCurrent()
            print("It took: \(beginTime - endTime) seconds to sync")
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
private func fetchAllEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [Entry]? {
        
//        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
//        var result: Entry? = nil
        do {
//            result = try context.fetch(fetchRequest).first
            let entries = try context.fetch(fetchRequest)
            return entries
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return nil
    }
    
    let context: NSManagedObjectContext
}

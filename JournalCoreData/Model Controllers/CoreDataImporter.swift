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

    func sync(entryRepresentations: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) -> [[Entry]] {
        var entriesArray: [Entry] = []
        self.context.performAndWait {
            self.identifierEntryRepresentationDictionary = entryRepresentations.toDictionary{ $0.identifier! }
            let coreDataEntriesDictionary = self.fetchEntriesFromPersistentStore(in: self.context)?.toDictionary{ $0.identifier }
            for entryRepresentation in entryRepresentations {
                guard let identifier = entryRepresentation.identifier else { continue }
                if let entry =  coreDataEntriesDictionary?[identifier] {
                    let updatedEntry = self.update(entry: entry, with: entryRepresentation)
                    entriesArray.append(updatedEntry)
                } else {
                    let newEntry = Entry(entryRepresentation: entryRepresentation, context: self.context)
                    entriesArray.append(newEntry!)
                }
                
                //                if let entry = entry(), entry != entryRep {
                //                    self.update(entry: entry, with: entryRep)
                //                } else if entry == nil {
                //                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                //                }
            }
            
            completion(nil)
            
        }
        let sortedEntriesArray = entriesArray.sorted { (leftEntry, rightEntry) -> Bool in
            return (leftEntry.timestamp)! > rightEntry.timestamp!
        }
        
        let filteredHappyEntriesArray = sortedEntriesArray.filter{ $0.mood == "🙂"}
        let filteredMehEntriesArray = sortedEntriesArray.filter{ $0.mood == "😐"}
        let filteredSadEntriesArray = sortedEntriesArray.filter{ $0.mood == "☹️"}
        let sectionArrays = [filteredHappyEntriesArray, filteredMehEntriesArray, filteredSadEntriesArray]
        return sectionArrays
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) -> Entry {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
        return entry
    }
    
    private func fetchEntriesFromPersistentStore(in context: NSManagedObjectContext) -> [Entry]? {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        
        var result: [Entry]?
            do {
                result = try context.fetch(fetchRequest)
            } catch {
                NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    private var identifierEntryRepresentationDictionary: [String : EntryRepresentation] = [:]
    
    let context: NSManagedObjectContext
}

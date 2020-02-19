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
            let entryRepWithID = entries.filter { $0.identifier != nil }
            let identifiersToFetch = entryRepWithID.compactMap { $0.identifier }
            let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entryRepWithID))
            var entriesToCreate = representationsByID
            
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
            
            
            
            self.context.perform {
                do {
                    let existingEntries = try self.context.fetch(fetchRequest)
                    
                    for entry in existingEntries {
                        guard
                            let id = entry.identifier,
                            let representation = representationsByID[id]
                            else { continue }
                        self.update(entry: entry, with: representation)
                        entriesToCreate.removeValue(forKey: id)
                    }
                    
                    for representation in entriesToCreate.values {
                        Entry(entryRepresentation: representation)
                    }
                    completion(nil)
                } catch {
                    NSLog("Error fetching entries for UUID's: \(error)")
                    completion(error)
                    return
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
    
//    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
//
//        guard let identifier = identifier else { return nil }
//
//        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifier)
//
//        var result: Entry? = nil
//        do {
//            result = try context.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching single entry: \(error)")
//        }
//        return result
//    }
    
    let context: NSManagedObjectContext
}

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
        
        let entryById = entries.filter { $0.identifier != nil }
        let identifiersToFetch = entryById.compactMap {$0.identifier!}
        
        let representationById = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entryById))
        
        var holdingDictionary = representationById
        
        //  hint 1: fetch request predicate can use the 'IN' operator to check for a value in array
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        self.context.perform {
            do {
                let dictionary = try self.context.fetch(fetchRequest)
                
                for entry in dictionary {
                    guard let id = entry.identifier,
                          let representation = representationById[id] else { continue }
                    
                    self.update(entry: entry, with: representation)
                    holdingDictionary.removeValue(forKey: id)
                }
                for representation in holdingDictionary.values {
                    _ = Entry(entryRepresentation: representation, context: self.context)
                }
                completion(nil)
            } catch {
                print("error fetching entries with corresponding id: \(error)")
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

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
    
//    print("start syncing: \(Date())")
//
//    let entry = self.fetchSingleEntryFromPersistentStore(entry: entries, in: self.context)
//
//    self.context.perform {
//
//      // Right now I am looping through each entry in the array to see if it has the same identifier
//
//      for entryRep in entries {
//        guard let identifier = entryRep.identifier else { continue }
//
//        let entry = entry![identifier]
//
//        // if it's an entry and if it's not the same as the representation
//        if let entry = entry, entry != entryRep {
//          // update to Firebase & Core Data
//          self.update(entry: entry, with: entryRep)
//        } else if entry == nil {
//          _ = Entry(entryRepresentation: entryRep, context: self.context)
//        }
//      }
//      completion(nil)
//      print("finish syncing: \(Date())")
//    }
    NSLog("Sync started")
    
    let identifiersToFetch = entries.compactMap { $0.identifier }
    let repsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, entries))
    var entriesToCreate = repsByID
    
    let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
    let context = CoreDataStack.shared.container.newBackgroundContext()
    
    self.context.perform {
      do {
        let existingEntries = try context.fetch(fetchRequest)
        for entry in existingEntries {
          guard let identifier = entry.identifier, let representation = repsByID[identifier] else { continue }
          self.update(entry: entry, with: representation)
          entriesToCreate.removeValue(forKey: identifier)
        }
        
        for representation in entriesToCreate.values {
          let _ = Entry(entryRepresentation: representation,context: context)
        }
        completion(nil)
        NSLog("Sync finished")
        
        
      } catch {
        print(error)
        return
      }
    }
    try? context.save()
    
  }
  
  // takes an Entry whose values should be updated, and an Entry Representation to take the values from
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


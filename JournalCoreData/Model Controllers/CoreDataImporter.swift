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
        
        
        let idsTofetch = entries.map {$0.identifier}
        let repsByID = Dictionary(uniqueKeysWithValues: zip(idsTofetch, entries))
        var entriesToCreate = repsByID
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", idsTofetch)
        let bgContext = CoreDataStack.shared.container.newBackgroundContext()
        
        bgContext.perform {
            do {
                
            let existingEntries = try bgContext.fetch(fetchRequest)
            
            for entry in existingEntries {
                guard let identifier = entry.identifier, let representation = repsByID[identifier] else { continue }
                self.update(entry: entry, with: representation)
                entriesToCreate.removeValue(forKey: identifier)
                }
                for rep in entriesToCreate.values {
                    let entry = Entry(entryRepresentation: rep, context: bgContext)
                }
                completion(nil)
            } catch {
                return
            }
            try? bgContext.save()
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    let context: NSManagedObjectContext
}

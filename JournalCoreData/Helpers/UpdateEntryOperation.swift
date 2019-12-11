//
//  UpdateEntryOperation.swift
//  JournalCoreData
//
//  Created by Jon Bash on 2019-12-10.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class UpdateEntryOperation: Operation {
    private(set) var entryRep: EntryRepresentation
    private(set) var entry: Entry?
    
    private var context: NSManagedObjectContext
    
    init(for entryRep: EntryRepresentation,
         with context: NSManagedObjectContext)
    {
        self.entryRep = entryRep
        self.context = context
    }
    
    override func main() {
        context.performAndWait {
            if let entry = fetchEntryFromStore() {
                self.entry = entry
                if entry != entryRep {
                    entry.update(with: entryRep)
                }
            } else {
                self.entry = Entry(
                    entryRepresentation: entryRep,
                    context: context)
            }
            do {
                try context.save()
            } catch {
                NSLog("Error saving to persistent store after updating entry from server: \(error)")
            }
        }
    }
    
    private func fetchEntryFromStore() -> Entry? {
        guard let identifier = entryRep.identifier else { return nil }
        
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
}

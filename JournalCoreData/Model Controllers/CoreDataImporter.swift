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
			let identifiers = entries.compactMap{ $0.identifier }
			let existingEntries = self.fetchEntriesFromPersistentStore(with: identifiers, in: self.context)
			for entryRep in entries {
				guard let identifier = entryRep.identifier else { continue }
				if let entry = existingEntries[identifier] {
					if entry != entryRep {
						self.update(entry: entry, with: entryRep)
					}
				} else {
					_ = Entry(entryRepresentation: entryRep, context: self.context)
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
	
	private func fetchEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [String?:Entry] {
		
		let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
		
		var results = [String?:Entry]()
		do {
			results = try context.fetch(fetchRequest).reduce(into: [String?:Entry]()) { (tResult, entry) in
				tResult[entry.identifier] = entry
			}
		} catch {
			NSLog("Error fetching single entry: \(error)")
		}
		return results
	}
    
    let context: NSManagedObjectContext
}

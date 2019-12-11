//
//  Entry+Convenience.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

extension Entry {
    
    var representation: EntryRepresentation? {
        return EntryRepresentation(
            title: self.title,
            bodyText: self.bodyText,
            mood: self.mood,
            timestamp: self.timestamp,
            identifier: self.identifier)
    }
    
    convenience init(title: String,
                     bodyText: String,
                     timestamp: Date = Date(),
                     mood: String,
                     identifier: String = UUID().uuidString,
                     context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        
        self.init(context: context)
        
        self.title = title
        self.bodyText = bodyText
        self.mood = mood
        self.timestamp = timestamp
        self.identifier = identifier
    }
    
    convenience init?(entryRepresentation: EntryRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        
        guard let title = entryRepresentation.title,
            let bodyText = entryRepresentation.bodyText,
            let mood = entryRepresentation.mood,
            let timestamp = entryRepresentation.timestamp,
            let identifier = entryRepresentation.identifier else { return nil }
        
        self.init(title: title, bodyText: bodyText, timestamp: timestamp, mood: mood, identifier: identifier, context: context)
    }
    
    func update(with entryRep: EntryRepresentation) {
        self.title = entryRep.title
        self.bodyText = entryRep.bodyText
        self.mood = entryRep.mood
        self.timestamp = entryRep.timestamp
        self.identifier = entryRep.identifier
    }
}

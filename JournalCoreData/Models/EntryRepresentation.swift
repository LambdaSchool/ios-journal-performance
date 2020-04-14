//
//  EntryRepresentation.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/14/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

struct EntryRepresentation: Codable {
    var title: String?
    var bodyText: String?
    var mood: String?
    var timestamp: Date?
    var identifier: String?

    init(title: String?, bodyText: String?, mood: String?, timestamp: Date?, identifier: String?) {
        self.title = title
        self.bodyText = bodyText
        self.mood = mood
        self.timestamp = timestamp
        self.identifier = identifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try? container.decode(String.self, forKey: .title)
        let bodyText = try? container.decode(String.self, forKey: .bodyText)
        let mood = try? container.decode(String.self, forKey: .mood)
        let timestamp = try? container.decode(Date.self, forKey: .timestamp)
        let identifier = try? container.decode(String.self, forKey: .identifier)

        self.init(title: title ?? "(none)",
                  bodyText: bodyText ?? "",
                  mood: mood ?? Mood.neutral.rawValue,
                  timestamp: timestamp ?? Date(),
                  identifier: identifier ?? UUID().uuidString)
    }

    enum CodingKeys: CodingKey {
        case title
        case bodyText
        case mood
        case timestamp
        case identifier
    }
}

func ==(lhs: EntryRepresentation, rhs: Entry) -> Bool {
    return rhs.title == lhs.title &&
        rhs.bodyText == lhs.bodyText &&
        rhs.mood == lhs.mood &&
        rhs.identifier == lhs.identifier
}

func ==(lhs: Entry, rhs: EntryRepresentation) -> Bool {
    return rhs == lhs
}

func !=(lhs: EntryRepresentation, rhs: Entry) -> Bool {
    return !(lhs == rhs)
}

func !=(lhs: Entry, rhs: EntryRepresentation) -> Bool {
    return rhs != lhs
}

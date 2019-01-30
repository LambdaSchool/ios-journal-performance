//
//  SequenceToDictionary.swift
//  JournalCoreData
//
//  Created by Austin Cole on 1/29/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

extension Sequence {
    public func toDictionary<Key: Hashable>(with selectKey: (Iterator.Element) -> Key) -> [Key:Iterator.Element] {
        var dict: [Key:Iterator.Element] = [:]
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}

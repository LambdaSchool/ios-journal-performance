//
//  SequenceToDictionary.swift
//  JournalCoreData
//
//  Created by Enzo Jimenez-Soto on 6/9/20.
//  Copyright © 2020 Lambda School. All rights reserved.
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


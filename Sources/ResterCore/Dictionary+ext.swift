//
//  Dictionary+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 14/02/2019.
//

import Foundation
import ValueCodable


enum MergeStrategy {
    case firstWins
    case lastWins
}


extension Dictionary {
    func merging(_ other: [Key : Value], strategy: MergeStrategy) -> [Key : Value] {
        switch strategy {
        case .firstWins:
            return self.merging(other, uniquingKeysWith: {old, _ in old})
        case .lastWins:
            return self.merging(other, uniquingKeysWith: {_, new in new})
        }
    }
}


extension Dictionary: Substitutable where Key == ValueCodable.Key, Value == ValueCodable.Value {
    func substitute(variables: [Key : Value]) throws -> Dictionary<Key, Value> {
        // TODO: consider transforming keys (but be aware that uniqueKeysWithValues
        // below will then trap at runtime if substituted keys are not unique)
        let substituted = try self.map { ($0.key, try $0.value.substitute(variables: variables)) }
        return Dictionary(uniqueKeysWithValues: substituted)
    }
}

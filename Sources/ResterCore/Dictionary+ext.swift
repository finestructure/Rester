//
//  Dictionary+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 14/02/2019.
//

import Foundation


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

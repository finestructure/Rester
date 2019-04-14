//
//  Data-ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 14/04/2019.
//

import Foundation


extension Data {
    var json: Value? {
        if let data = try? JSONDecoder().decode([Key: Value].self, from: self) {
            return .dictionary(data)
        } else if let data = try? JSONDecoder().decode([Value].self, from: self) {
            return .array(data)
        } else {
            return nil
        }
    }
}

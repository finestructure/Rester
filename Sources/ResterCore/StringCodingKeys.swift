//
//  StringCodingKeys.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 10/03/2019.
//

import Foundation


struct StringCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String

    init?(intValue: Int) {
        return nil
    }

    init?(stringValue: String){
        self.stringValue = stringValue
    }
}


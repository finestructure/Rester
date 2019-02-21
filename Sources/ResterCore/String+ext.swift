//
//  String+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation


extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

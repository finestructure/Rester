//
//  String+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation


extension String {
    public func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}


extension String: URLEncoding {
    public var urlEncoded: String? {
        let allowed = CharacterSet.urlHostAllowed.subtracting(CharacterSet(charactersIn: "+"))
        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
}


extension String {
    public var base64: String {
        return Data(self.utf8).base64EncodedString()
    }
}

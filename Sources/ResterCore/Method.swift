//
//  Method.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public enum Method: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

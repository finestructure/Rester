//
//  Response.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public struct Response: Equatable {
    let data: Data
    let response: HTTPURLResponse

    var status: Int {
        return response.statusCode
    }
}

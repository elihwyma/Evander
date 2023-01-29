//
//  Multipart.swift
//  Evander
//
//  Created by Amy While on 02/10/2022.
//

import Foundation

public struct Multipart {
    
    let name: String
    let type: String
    let data: Data
    
    public init(name: String, type: String, data: Data) {
        self.name = name
        self.type = type
        self.data = data
    }
    
}

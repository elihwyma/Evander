//
//  NetworkSessionType.swift
//  Evander
//
//  Created by Somica on 03/10/2022.
//

import Foundation

public enum NetworkSessionType {
    
    case `default`
    case ephemeral
    case background(identifier: String)
    
}

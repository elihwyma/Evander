//
//  NetworkRequestContentType.swift
//  Evander
//
//  Created by Amy While on 02/10/2022.
//

import Foundation

public enum NetworkRequestContentType: String {
    
    case form = "application/x-www-form-urlencoded"
    case json = "application/json"
    case multipart = "multipart/form-data; boundary="
    
}

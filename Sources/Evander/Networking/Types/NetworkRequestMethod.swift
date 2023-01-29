//
//  NetworkRequestMethod.swift
//  Evander
//
//  Created by Amy While on 02/10/2022.
//

import Foundation

public enum NetworkRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case head = "HEAD"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}

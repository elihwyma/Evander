//
//  Logging.swift
//  
//
//  Created by Amy While on 08/01/2022.
//

import Foundation

public func EVLog(_ log: Any, separator: String = " ", terminator: String = "\n", file: String = #fileID, lineNumber: Int = #line, function: String = #function) {
    print("[\(file)/\(lineNumber)/\(function)] \(log)", separator: separator, terminator: terminator)
}

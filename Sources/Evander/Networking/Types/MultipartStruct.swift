//
//  MultipartData.swift
//  Evander
//
//  Created by Amy While on 02/10/2022.
//

import Foundation

internal struct MultipartStruct {
    
    internal let boundary = UUID().uuidString
    private var body = Data()
    
    internal mutating func add(json: [AnyHashable: AnyHashable?]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
            add(name: "payload_json", contentType: "application/json", data: jsonData)
        }
    }
    
    internal mutating func add(multipart: [Multipart]) {
        for (index, multipart) in multipart.enumerated() {
            let name = multipart.name
            let fileType = multipart.type
            add(name: "\(name)\(index)", filename: "\(name)\(index).\(fileType)", contentType: "\(name)\(index).\(fileType)", data: multipart.data)
        }
    }
    
    private mutating func add(name: String, filename: String, contentType: String, data: Data) {
        body.append(
            "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\nContent-Type: \(contentType)\r\n\r\n\(data)".data(using: .utf8)!
        )
    }
    
    private mutating func add(name: String, contentType: String, data: Data) {
        body.append(
            "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\"\r\nContent-Type: \(contentType)\r\n\r\n\(data)".data(using: .utf8)!
        )
    }

    internal var requestBody: Data {
        var body = body
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
}

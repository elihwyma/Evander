//
//  mDate.swift
//  Medusa
//
//  Created by Amy While on 29/10/2022.
//

import Foundation

public struct mDate: Codable, Hashable, Equatable {
    
    public let raw: Date
    
    private static let secondaryFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private static let primaryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Date.self) {
            self.raw = x
            return
        }
        if let x = try? container.decode(String.self) {
            if let raw = Self.primaryFormatter.date(from: x) {
                self.raw = raw
                return
            }
            if let raw = Self.secondaryFormatter.date(from: x) {
                self.raw = raw
                return
            }
            throw DecodingError.typeMismatch(mDate.self, .init(codingPath: decoder.codingPath, debugDescription: "Failed decoding date: \(x)"))
        }
        if let x = try? container.decode(Int64.self) {
            self.raw = Date(timeIntervalSince1970: TimeInterval(x))
            return
        }
        if let x = try? container.decode(Double.self) {
            self.raw = Date(timeIntervalSince1970: x)
            return
        }
        throw DecodingError.typeMismatch(mDate.self, .init(codingPath: decoder.codingPath, debugDescription: "Unknown date format"))
    }
 
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
    
}

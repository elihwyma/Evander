//
//  NetworkResponse.swift
//  Evander
//
//  Created by Somica on 05/10/2022.
//

import Foundation

protocol NetworkResponse {
    var status: Int { get }
    var success: Bool { get }
    var error: Error? { get }
}

public struct NetworkJSONResponse: NetworkResponse {
    
    internal init(status: Int, success: Bool, error: Error?, json: [String : AnyHashable?]?) {
        self.status = status
        self.success = success
        self.error = error
        self.json = json
    }
    
    let status: Int
    
    let success: Bool
    
    let error: Error?
    
    let json: [String: AnyHashable?]?
    
}

public struct NetworkCodableResponse<T: Decodable>: NetworkResponse {
    
    internal init(status: Int, success: Bool, error: Error?, data: T?) {
        self.status = status
        self.success = success
        self.error = error
        self.data = data
    }
    
    let status: Int
    
    let success: Bool
    
    let error: Error?
    
    let data: T?
    
}

public struct NetworkDataResponse: NetworkResponse {
    
    internal init(status: Int, success: Bool, error: Error?, data: Data?) {
        self.status = status
        self.success = success
        self.error = error
        self.data = data
    }
    
    let status: Int
    
    let success: Bool
    
    let error: Error?
    
    let data: Data?
    
}

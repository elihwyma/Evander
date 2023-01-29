//
//  NetworkSocketDelegate.swift
//  Evander
//
//  Created by Amy While on 06/10/2022.
//

import Foundation

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
public protocol NetworkSocketDelegate: AnyObject {
    func didOpen()
    func didCloseWithError(error: Error?)
    func didCloseWithCode(code: URLSessionWebSocketTask.CloseCode, reason: Data?)
    func didReceiveString(string: String)
    func didReceiveData(data: Data)
}

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
extension NetworkSocketDelegate {
    
    public func didReceiveString(string: String) {
        
    }
    
    public func didReceiveData(data: Data) {
        
    }
    
    public func didOpen() {
        
    }
    
}

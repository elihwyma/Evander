//
//  NetworkSessionConfig.swift
//  Evander
//
//  Created by Somica on 03/10/2022.
//

import Foundation

public struct NetworkSessionConfig {
    
    internal let configuration: URLSessionConfiguration
    
    public var httpAdditionalHeaders: [AnyHashable: String]?
    public var totalCostLimit = 0//1024 * 1024 * 128
    public var allowsCellularAccess = true
    public var requestCachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
    public var networkServiceType: NSURLRequest.NetworkServiceType = .default
    public var httpCookieAcceptPolicy: HTTPCookie.AcceptPolicy = .never
    public var httpShouldSetCookies = true
    public var waitsForConnectivity = true
    #if os(iOS)
    public var multipath: URLSessionConfiguration.MultipathServiceType = .handover
    #endif
    
    public init(configuration: NetworkSessionType) {
        switch configuration {
        case .`default`:
            self.configuration = .`default`
        case .ephemeral:
            self.configuration = .ephemeral
        case .background(identifier: let identifier):
            self.configuration = .background(withIdentifier: identifier)
        }
    }
    
    internal var sessionConfiguration: URLSessionConfiguration {
        configuration.httpAdditionalHeaders = httpAdditionalHeaders
        configuration.allowsCellularAccess = allowsCellularAccess
        configuration.requestCachePolicy = requestCachePolicy
        configuration.networkServiceType = networkServiceType
        configuration.httpCookieAcceptPolicy = httpCookieAcceptPolicy
        configuration.httpShouldSetCookies = httpShouldSetCookies
        configuration.waitsForConnectivity = waitsForConnectivity
        
        #if os(iOS)
        configuration.multipathServiceType = multipath
        #endif
        
        
        return configuration
    }
        
}

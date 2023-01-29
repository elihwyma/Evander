//
//  NetworkRequest.swift
//  
//
//  Created by Amy While on 02/10/2022.
//

import Foundation

public struct NetworkRequest {
    
    // URL of the request
    internal let url: URL
    // HTTP Method
    public var method: NetworkRequestMethod = .get
    // Value for Content-Type HTTP Header, if not assigned the body will be nil
    public var contentType: NetworkRequestContentType?
    
    // HTTP headers
    public var headers: [String: String] = [:]
    // JSON Body
    public var json: [AnyHashable: AnyHashable?]? {
        didSet {
            contentType = .json
        }
    }
    // HTTP Form Data
    public var form: [String: AnyHashable]? {
        didSet {
            contentType = .form
        }
    }
    // Multipart Data
    public var multipart: [Multipart]? {
        didSet {
            contentType = .multipart
        }
    }
    
    // Request Timeout Interval
    public var timeoutInterval: TimeInterval = 60
    // Request Cache Policy
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    // Allow Mobile Data
    public var allowsCellularAccess: Bool = true
    // Should send/set cookies
    public var httpShouldHandleCookies: Bool = true
    // Allow constrained access (low data mode)
    public var allowsConstrainedNetworkAccess: Bool = true
    // Allow expensive data use (power hungry)
    public var allowsExpensiveNetworkAccess: Bool = true
    // Network service type, please try to be accurate
    public var networkServiceType: URLRequest.NetworkServiceType = .default
    
    // Init the request with a URL
    public init(url: URL) {
        self.url = url
    }
    
    // Make a URLRequest with the required data
    internal var request: URLRequest {
        // Initialise the request
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        
        // Set all the user defined properties
        request.allowsCellularAccess = allowsCellularAccess
        request.httpShouldHandleCookies = httpShouldHandleCookies
        if #available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *) {
            request.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
            request.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        }
        request.networkServiceType = networkServiceType
        request.httpMethod = method.rawValue
    
        // Set all HTTP Headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set the appropriate content for the content type
        if let contentType {
            switch contentType {
            case .json:
                request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
                if let json,
                   let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                    request.httpBody = jsonData
                }
            case .form:
                request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
                if let form,
                   let bodyString = form.map({ "\($0.key)=\($0.value)" }).joined(separator: "&")
                                        .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                    request.httpBody = bodyString.data(using: .utf8)
                }
            case .multipart:
                var multipartHandler = MultipartStruct()
                request.setValue(contentType.rawValue + multipartHandler.boundary, forHTTPHeaderField: "Content-Type")
                if let json {
                    multipartHandler.add(json: json)
                }
                if let multipart {
                    multipartHandler.add(multipart: multipart)
                }
                request.httpBody = multipartHandler.requestBody
            }
        }
        
        return request
    }
}

//
//  NetworkSession.swift
//  Medusa
//
//  Created by Somica on 03/10/2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Make sparingly, can cause a rate limit!!!
final public class NetworkSession {
    
    // Only init the image cache if its ever used
    private lazy var preparedImageCache: NSCache<NSURL, Image> = {
        let cache = NSCache<NSURL, Image>()
        cache.totalCostLimit = configuration.totalCostLimit
        return cache
    }()
    
    private let configuration: NetworkSessionConfig
    private let session: URLSession
    
    public enum NetworkErrors: Error {
        case invalidData
        case invalidImage
        case invalidURL
        
        public var localizedDescription: String {
            switch self {
            case .invalidData: return "Server returned invalid data"
            case .invalidImage: return "Image could not be processed"
            case .invalidURL: return "Provided URL was invalid"
            }
        }
    }
    
    public init(configuration: NetworkSessionConfig) {
        self.configuration = configuration
        self.session = URLSession(configuration: configuration.sessionConfiguration)
    }
    
    public func dataRequest(request: NetworkRequest, completion: @escaping (NetworkDataResponse) -> Void) {
        session.dataTask(with: request.request) { data, response, error in
            if let error = error {
                return completion(.init(status: 500, success: false, error: error, data: nil))
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            return completion(.init(status: statusCode, success: true, error: nil, data: data))
        }.resume()
    }

    public func request<T: Decodable>(request: NetworkRequest, type: T, completion: @escaping (NetworkCodableResponse<T>) -> Void) {
        session.dataTask(with: request.request) { data, response, error in
            if let error = error {
                return completion(.init(status: 500, success: false, error: error, data: nil))
            }
            var responseData: T?
            do {
                if let data = data {
                    responseData = try mJSONDecoder().decode(T.self, from: data)
                }
            } catch {
                return completion(.init(status: 500, success: false, error: error, data: nil))
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            return completion(.init(status: statusCode, success: true, error: nil, data: responseData))
        }.resume()
    }
    
    public func request(request: NetworkRequest, completion: @escaping (NetworkJSONResponse) -> Void) {
        session.dataTask(with: request.request) { data, response, error in
            if let error = error {
                return completion(.init(status: 500, success: false, error: error, json: nil))
            }
            var json: [String: AnyHashable?]?
            if let data = data,
               let _json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyHashable?] {
                json = _json
            }
            do {
                if let data = data {
                    json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyHashable?]
                }
            } catch {
                return completion(.init(status: 500, success: false, error: error, json: nil))
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            return completion(.init(status: statusCode, success: true, error: nil, json: json))
        }.resume()
    }
    
    public func imageRequest(for request: NetworkRequest, size: CGSize, animated: Bool, completion: @escaping (Image?) -> Void) {
        if let image = preparedImageCache.object(forKey: request.url as NSURL) {
            return completion(image)
        }
        
        func done(image: Image?, size: Int = 0) {
            guard let image = image else { return completion(nil) }
            preparedImageCache.setObject(image, forKey: request.url as NSURL, cost: size)
            return completion(image)
        }
        
        self.dataRequest(request: request) { response in
            if let data = response.data {
                if animated {
                    ImageProcessing.dispatchQueue.async {
                        let gif = EvanderGIF(data: data, size: size) { image in
                            completion(image)
                        }
                        done(image: gif, size: data.count)
                    }
                } else {
                    ImageProcessing.downsample(data: data, to: size) { image in
                        done(image: image, size: data.count)
                    }
                }
            }
        }
    }
    
    public func imageRequest(for url: URL?, size: CGSize, animated: Bool, completion: @escaping (Image?) -> Void) {
        guard let url = url else { return completion(nil) }
        
        var request = NetworkRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        
        return imageRequest(for: request, size: size, animated: animated, completion: completion)
    }
    
    public func imageRequest(for string: String?, size: CGSize, animated: Bool, completion: @escaping (Image?) -> Void) {
        guard let surl = string else { return completion(nil) }
        return imageRequest(for: URL(string: surl), size: size, animated: animated, completion: completion)
    }
    
}

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
public extension NetworkSession {
    
    func dataRequest(request: NetworkRequest) async throws -> NetworkDataResponse {
        try await withCheckedThrowingContinuation { continuation in
            dataRequest(request: request) { dataResponse in
                if let error = dataResponse.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: dataResponse)
                }
            }
        }
    }
    
    func request<T: Decodable>(request: NetworkRequest, type: T) async throws -> NetworkCodableResponse<T> {
        try await withCheckedThrowingContinuation { continuation in
            self.request(request: request, type: type) { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: response)
                }
            }
        }
    }
    
    func request(request: NetworkRequest) async throws -> NetworkJSONResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.request(request: request) { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: response)
                }
            }
        }
    }
    
    func imageRequest(for request: NetworkRequest, size: CGSize, animated: Bool) async throws -> Image {
        if let image = preparedImageCache.object(forKey: request.url as NSURL) {
            return image
        }
        let dataResponse = try await self.dataRequest(request: request)
        guard let data = dataResponse.data else {
            throw NetworkErrors.invalidData
        }
        if animated {
            guard let gif = await EvanderGIF(data: data, size: size) else {
                throw NetworkErrors.invalidImage
            }
            preparedImageCache.setObject(gif, forKey: request.url as NSURL)
            return gif
        } else {
            guard let image = await ImageProcessing.downsample(data: data, to: size) else {
                throw NetworkErrors.invalidImage
            }
            preparedImageCache.setObject(image, forKey: request.url as NSURL)
            return image
        }
    }
    
    func imageRequest(for url: URL?, size: CGSize, animated: Bool) async throws -> Image {
        guard let url else {
            throw NetworkErrors.invalidURL
        }
        var req = NetworkRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        return try await imageRequest(for: req, size: size, animated: animated)
    }
    
    func imageRequest(for string: String?, size: CGSize, animated: Bool) async throws -> Image {
        guard let string else {
            throw NetworkErrors.invalidURL
        }
        return try await imageRequest(for: URL(string: string), size: size, animated: animated)
    }
    
}

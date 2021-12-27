//  Created by Amy on 23/03/2021.
//  Copyright © 2021 Amy While. All rights reserved.
//

import UIKit

final public class EvanderNetworking {
    
    static let MANIFEST_VERSION = "1.0"
    public static var CACHE_FORCE: FileManager.SearchPathDirectory = .cachesDirectory

    // swiftlint:disable force_cast
    public static var _cacheDirectory: URL = {
        FileManager.default.urls(for: CACHE_FORCE, in: .userDomainMask)[0]
            .appendingPathComponent((Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String).replacingOccurrences(of: " ", with: ""))
    }()
    // swiftlint:enable force_cast
    
    public static var downloadCache: URL = {
        _cacheDirectory.appendingPathComponent("Downloads")
    }()
    
    public static var networkCache: URL {
        _cacheDirectory.appendingPathComponent("Networking")
    }
    
    public static var mediaCache: URL {
        _cacheDirectory.appendingPathComponent("Media")
    }
    
    public static var localeCache: URL {
        _cacheDirectory.appendingPathComponent("Locale")
    }
    
    private static var manifest: URL {
        _cacheDirectory.appendingPathComponent(".MANIFEST")
    }

    private class Callback: NSObject {
        private static let callbackQueue: DispatchQueue = {
            let queue = DispatchQueue(label: "EvanderNetworking/CallbackQueue", qos: .utility)
            queue.setSpecific(key: Callback.queueKey, value: Callback.queueContext)
            return queue
        }()
        private static let queueKey = DispatchSpecificKey<Int>()
        private static var queueContext = 3042
        
        public var callbacks = SafeArray<(UIImage) -> Void>(queue: callbackQueue, key: queueKey, context: queueContext)
        
        init(_ callback: @escaping (UIImage) -> Void) {
            super.init()
            add(callback)
        }
        
        public func add(_ callback: @escaping (UIImage) -> Void) {
            callbacks.append(callback)
        }
    }
    
    public static var memoryCache = NSCache<NSString, UIImage>()
    private static var callbackCache = NSCache<NSURL, Callback>()

    
    public class func clearCache() {
        try? FileManager.default.removeItem(at: downloadCache)
        try? FileManager.default.removeItem(at: networkCache)
        try? FileManager.default.removeItem(at: mediaCache)
        try? FileManager.default.removeItem(at: localeCache)
        setupCache()
    }
    
    private class func validateManifest() -> Bool {
        if manifest.exists,
            let text = try? String(contentsOf: manifest),
            text == MANIFEST_VERSION {
            return true
        }
        if !_cacheDirectory.dirExists {
            do {
                try FileManager.default.createDirectory(atPath: _cacheDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create cache directory \(error.localizedDescription)")
            }
        }
        try? MANIFEST_VERSION.write(to: manifest, atomically: false, encoding: .utf8)
        return false
    }
    
    private class func cleanup() {
        if manifest.exists {
            return
        }
        try? FileManager.default.removeItem(at: _cacheDirectory)
        
    }
    
    public class func setupCache() {
        func create(_ url: URL) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create cache directory \(error.localizedDescription)")
            }
        }
        func check(_ urls: [URL]) {
            for url in urls {
                if !url.dirExists {
                    create(url)
                }
            }
        }
        cleanup()
        if !validateManifest() {
            clearCache()
            return
        }
        check([
            _cacheDirectory,
            downloadCache,
            networkCache,
            mediaCache,
            localeCache
        ])        
        DispatchQueue.global(qos: .utility).async { [self] in
            var combined = [URL]()
            combined += mediaCache.implicitContents
            combined += networkCache.implicitContents
            for content in combined {
                guard let attr = try? FileManager.default.attributesOfItem(atPath: content.path),
                      let date = attr[FileAttributeKey.modificationDate] as? Date else { continue }
                if Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 604800) > date {
                    try? FileManager.default.removeItem(atPath: content.path)
                }
            }
            if let contents = try? self.downloadCache.contents() {
                for cached in contents {
                    try? FileManager.default.removeItem(atPath: cached.path)
                }
            }
        }
    }

    public struct CacheConfig {
        public var localCache: Bool
        public var skipNetwork: Bool
        
        public init(localCache: Bool = true, skipNetwork: Bool = false) {
            self.localCache = localCache
            self.skipNetwork = skipNetwork
        }
    }

    class private func skipNetwork(_ url: URL) -> Bool {
        if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
           let date = attr[FileAttributeKey.modificationDate] as? Date {
            var yes = DateComponents()
            yes.day = -1
            let yesterday = Calendar.current.date(byAdding: yes, to: Date()) ?? Date()
            if date > yesterday {
                return true
            }
        }
        return false
    }

    class public func checkCache<T: Any>(for url: URL, type: T.Type) -> T? {
        let encoded = url.absoluteString.toBase64
        let path = Self.networkCache.appendingPathComponent("\(encoded).json")
        if let data = try? Data(contentsOf: path),
           let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T {
            return dict
        }
        return nil
    }
    
    public typealias Response<T: Any> = ((Bool, Int?, Error?, T?) -> Void)
    
    class public func request<T: Any>(request: URLRequest, type: T.Type, cache: CacheConfig = .init(), _ completion: @escaping Response<T>) {
        var cachedData: Data?
        guard let url = request.url else { return completion(false, nil, nil, nil) }
        let encoded = url.absoluteString.toBase64
        let path = Self.networkCache.appendingPathComponent("\(encoded).json")
        
        if cache.localCache {
            if let data = try? Data(contentsOf: path) {
                if T.self == Data.self {
                    if cache.skipNetwork && skipNetwork(path) {
                        return completion(true, nil, nil, data as? T)
                    } else {
                        cachedData = data
                        completion(true, nil, nil, data as? T)
                    }
                } else {
                    if let decoded = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T {
                        if cache.skipNetwork && skipNetwork(path) {
                            return completion(true, nil, nil, decoded)
                        } else {
                            cachedData = data
                            completion(true, nil, nil, decoded)
                        }
                    }
                }
            }
        }
        URLSession.shared.dataTask(with: request) { data, response, error -> Void in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            var returnData: T?
            var success: Bool = false
            if let data = data {
                if T.self == Data.self {
                    returnData = data as? T
                    success = true
                    if cache.localCache {
                        try? data.write(to: path, options: .atomic)
                    }
                    if cachedData == data { return }
                } else if let decoded = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T {
                    returnData = decoded
                    success = true
                    if cache.localCache {
                        try? data.write(to: path, options: .atomic)
                    }
                    if cachedData == data { return }
                }
            }
            return completion(success, statusCode, error, returnData)
        }.resume()
    }
    
    class public func request<T: Any>(url: String?, type: T.Type, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable]? = nil, multipart: [[String: Data]]? = nil, cache: CacheConfig = .init(), _ completion: @escaping Response<T>) {
        guard let _url = url,
              let url = URL(string: _url) else { return completion(false, nil, nil, nil) }
        request(url: url, type: type, method: method, headers: headers, json: json, multipart: multipart, cache: cache, completion)
    }
    
    class public func request<T: Any>(url: URL, type: T.Type, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable]? = nil, multipart: [[String: Data]]? = nil, cache: CacheConfig = .init(), _ completion: @escaping Response<T>) {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let multipart = multipart {
            let boundary = UUID().uuidString
            var body = Data()
            func addString(_ string: String) {
                guard let data = string.data(using: .utf8) else { return }
                body.append(data)
            }
            if let json = json,
               !json.isEmpty,
               let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                body.addMultiPart(boundary: boundary, name: "payload_json", contentType: "application/json", data: jsonData)
            }
            for (index, item) in multipart.enumerated() {
                if item.keys.count != 1 { continue }
                let contentType = item.keys.first!
                let components = contentType.split(separator: "/")
                guard components.count == 2 else { continue }
                let fileType = components.last!
                let name = components.first!
                let data = item[contentType]!
                body.addMultiPart(boundary: boundary, name: "\(name)\(index)", filename: "\(name)\(index).\(fileType)", contentType: "\(name)/\(fileType)", data: data)
            }
            body.addMultiPartEnd(boundary: boundary)
            request.httpBody = body as Data
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        } else if let json = json,
                  !json.isEmpty,
                  let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
           request.httpBody = jsonData
           request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        Self.request(request: request, type: type, cache: cache, completion)
    }
    
    class public func head(url: String?, _ completion: @escaping ((_ success: Bool) -> Void)) {
        guard let surl = url,
              let url = URL(string: surl) else { return completion(false) }
        head(url: url, completion)
    }
    
    class public func head(url: URL, _ completion: @escaping ((_ success: Bool) -> Void)) {
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { _, response, _ -> Void in
            if let response = response as? HTTPURLResponse,
               response.statusCode == 200 { completion(true) } else { completion(false) }
        }
        task.resume()
    }
    
    public class func image(url: URL?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, _ completion: @escaping (UIImage) -> Void) -> UIImage? {
        guard let url = url else { return nil }
        let encoded = url.absoluteString.toBase64
        if cache.localCache || cache.skipNetwork,
           let image = memoryCache.object(forKey: encoded as NSString) {
            return image
        }
        var size = size
        if size?.height == 0 || size?.width == 0 {
            size = nil
        }
        
        func work() -> UIImage? {
            if url.scheme == "file" {
                if url.exists,
                   let image = ImageProcessing.downsample(url: url, to: size, scale: scale) {
                    return image
                }
                return nil
            }
            let path = mediaCache.appendingPathComponent("\(encoded).png")
            if path.exists,
               let image = ImageProcessing.downsample(url: path, to: size, scale: scale) {
                if cache.localCache || cache.skipNetwork {
                    memoryCache.setObject(image, forKey: encoded as NSString)
                    if cache.skipNetwork && Self.skipNetwork(path) {
                        return image
                    }
                } else {
                    completion(image)
                }
            }
            
            if let callback = callbackCache.object(forKey: url as NSURL) {
                callback.add(completion)
            } else {
                callbackCache.setObject(Callback(completion), forKey: url as NSURL)
                request(url: url, type: Data.self, method: method, headers: headers, json: nil, multipart: nil, cache: .init(localCache: false, skipNetwork: false)) { _, _, _, data in
                    guard let data = data,
                          var image = UIImage(data: data) else { return }
                    image = ImageProcessing.downsample(image: image, to: size, scale: scale) ?? image
                    if let callback = callbackCache.object(forKey: url as NSURL) {
                        for callback in callback.callbacks.raw {
                            callback(image)
                        }
                    } else {
                        completion(image)
                    }
                    memoryCache.setObject(image, forKey: encoded as NSString)
                    try? image.pngData()?.write(to: path)
                }
            }
            return nil
        }
        
        return work()
    }
    
    public class func image(url: String?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, _ completion: @escaping (UIImage) -> Void) -> UIImage? {
        guard let _url = url,
              let url = URL(string: _url) else {
             return nil
        }
        return image(url: url, method: method, headers: headers, cache: cache, scale: scale, size: size, completion: completion)
    }
    
    public class func image(url: URL?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, condition: @escaping () -> (Bool), imageView: UIImageView?, fallback: UIImage? = nil) {
        image(url: url, method: method, headers: headers, cache: cache, scale: scale, size: size, condition: condition, imageViews: [imageView], fallback: fallback)
    }
    
    public class func image(url: URL?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, condition: @escaping () -> (Bool), imageViews: [UIImageView?], fallback: UIImage? = nil) {
        if let image = image(url: url, method: method, headers: headers, cache: cache, scale: scale, size: size, completion: { image in
            Thread.mainBlock {
                if condition() {
                    imageViews.forEach { $0?.image = image }
                }
            }
        }) {
            Thread.mainBlock {
                if condition() {
                    imageViews.forEach { $0?.image = image }
                }
            }
        } else {
            Thread.mainBlock {
                if condition() {
                    imageViews.forEach { $0?.image = fallback }
                }
            }
        }
    }
    
    public class func image(url: String?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, condition: @escaping () -> (Bool), imageView: UIImageView?, fallback: UIImage? = nil) {
        image(url: url, method: method, headers: headers, cache: cache, scale: scale, size: size, condition: condition, imageViews: [imageView], fallback: fallback)
    }
    
    public class func image(url: String?, method: String = "GET", headers: [String: String] = [:], cache: CacheConfig = .init(localCache: true, skipNetwork: true), scale: CGFloat? = nil, size: CGSize? = nil, condition: @escaping () -> (Bool), imageViews: [UIImageView?], fallback: UIImage? = nil) {
        guard let _url = url,
              let url = URL(string: _url) else {
            Thread.mainBlock {
                if condition() {
                    imageViews.forEach { $0?.image = fallback }
                }
            }
            return
        }
        image(url: url, method: method, headers: headers, cache: cache, scale: scale, size: size, condition: condition, imageViews: imageViews, fallback: fallback)
    }
    
    public class func gif(_ url: String, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        guard let url = URL(string: url) else { return nil }
        return self.gif(url, method: method, headers: headers, cache: cache, scale: scale, size: size, completion)
    }
    
    public class func gif(_ url: URL, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return nil
        }
        var size = size
        if size?.height == 0 || size?.width == 0 {
            size = nil
        }
        var pastData: Data?
        var returnImage: UIImage?
        let encoded = url.absoluteString.toBase64
        if cache,
           let image = memoryCache.object(forKey: encoded as NSString) {
            return image
        }
        let path = mediaCache.appendingPathComponent("\(encoded).gif")
        if path.exists {
            if let data = try? Data(contentsOf: path) {
                if let image = EvanderGIF(data: data, size: size, scale: scale) {
                    if cache {
                        memoryCache.setObject(image, forKey: encoded as NSString)
                        pastData = data
                        if Self.skipNetwork(path) {
                            return image
                        } else {
                            returnImage = image
                        }
                    } else {
                        return image
                    }
                }
            }
        }
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let task = URLSession.shared.dataTask(with: request) { [self] data, _, _ -> Void in
            if let data = data,
               let image = EvanderGIF(data: data, size: size, scale: scale) {
                completion?(pastData != data, image)
                if cache {
                    memoryCache.setObject(image, forKey: encoded as NSString)
                    do {
                        if !mediaCache.dirExists {
                            try FileManager.default.createDirectory(at: mediaCache, withIntermediateDirectories: true)
                        }
                        try data.write(to: path, options: .atomic)
                    } catch {
                        print("Error saving to \(path.absoluteString) with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        task.resume()
        return returnImage
    }
    
    public class func saveCache(_ url: URL, data: Data) {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return
        }
        let encoded = url.absoluteString.toBase64
        let path = mediaCache.appendingPathComponent("\(encoded).png")
        do {
            try data.write(to: path, options: .atomic)
        } catch {
            print("Error saving to \(path.absoluteString) with error: \(error.localizedDescription)")
        }
    }
    
    public class func imageCache(_ url: URL, scale: CGFloat? = nil, size: CGSize? = nil) -> (Bool, UIImage?) {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return (true, nil)
        }
        let encoded = url.absoluteString.toBase64
        let path = mediaCache.appendingPathComponent("\(encoded).png")
        if let memory = memoryCache.object(forKey: encoded as NSString) {
            return (!Self.skipNetwork(path), memory)
        }
        if path.exists {
            if let image = ImageProcessing.downsample(url: path, to: size, scale: scale) {
                return (!Self.skipNetwork(path), image)
            }
        }
        return (true, nil)
    }
}

fileprivate extension Data {
    
    mutating func addMultiPart(boundary: String, name: String, filename: String, contentType: String, data: Data) {
        append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        append(data)
    }
    
    mutating func addMultiPart(boundary: String, name: String, contentType: String, data: Data) {
        append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        append(data)
    }
    
    mutating func addMultiPartEnd(boundary: String) {
        append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    }
    
}



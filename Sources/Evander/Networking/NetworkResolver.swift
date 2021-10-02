//  Created by Amy on 23/03/2021.
//  Copyright © 2021 Amy While. All rights reserved.
//

import UIKit

final public class EvanderNetworking {
    
    static public let shared = EvanderNetworking()
    
    // swiftlint:disable force_cast
    lazy public var cacheDirectory: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent((Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String).replacingOccurrences(of: " ", with: ""))
    }()
    // swiftlint:enable force_cast
    
    lazy public var downloadCache: URL = {
        cacheDirectory.appendingPathComponent("DownloadCache")
    }()
    
    public var memoryCache = NSCache<NSString, UIImage>()

    
    public func clearCache() {
        if cacheDirectory.dirExists {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
        setupCache()
    }
    
    public func setupCache() {
        if !cacheDirectory.dirExists {
            do {
                try FileManager.default.createDirectory(atPath: cacheDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create cache directory \(error.localizedDescription)")
            }
        }
        if !downloadCache.dirExists {
            do {
                try FileManager.default.createDirectory(atPath: downloadCache.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create cache directory \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.global(qos: .utility).async { [self] in
            if let contents = try? cacheDirectory.contents(),
               !contents.isEmpty {
                for cached in contents {
                    if cached == downloadCache { continue }
                    guard let attr = try? FileManager.default.attributesOfItem(atPath: cached.path),
                          let date = attr[FileAttributeKey.modificationDate] as? Date else { continue }
                    if Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 604800) > date {
                        try? FileManager.default.removeItem(atPath: cached.path)
                    }
                }
            }
            if !downloadCache.dirExists {
                do {
                    try FileManager.default.createDirectory(atPath: downloadCache.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create cache directory \(error.localizedDescription)")
                }
            }
            if let contents = try? self.downloadCache.contents(),
               !contents.isEmpty {
                for cached in contents {
                    try? FileManager.default.removeItem(atPath: cached.path)
                }
            }
        }
    }
 
    init() {
        setupCache()
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
    
    class public func dict(request: URLRequest, cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ dict: [String: Any]?) -> Void)) {
        var pastData: Data?
        if cache {
            if let url = request.url {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                if let data = try? Data(contentsOf: path),
                   let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if skipNetwork(path) {
                        return completion(true, dict)
                    } else {
                        pastData = data
                        completion(true, dict)
                    }
                }
            }
        }
        Self.request(request) { success, data -> Void in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                if let url = request.url {
                    let encoded = url.absoluteString.toBase64
                    let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                    try? data.write(to: path)
                }
            }
            if pastData == data { return }
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] ?? [String: Any]()
                return completion(true, dict)
            } catch {}
            return completion(false, nil)
        }
    }
    
    class public func dict(url: String?, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ dict: [String: Any]?) -> Void)) {
        guard let surl = url,
              let url = URL(string: surl) else { return completion(false, nil) }
        Self.dict(url: url, method: method, headers: headers, json: json, cache: cache) { success, dict -> Void in
            completion(success, dict)
        }
    }
    
    class public func dict(url: URL, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ dict: [String: Any]?) -> Void)) {
        var pastData: Data?
        if cache {
            let encoded = url.absoluteString.toBase64
            let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
            if let data = try? Data(contentsOf: path),
               let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                if skipNetwork(path) {
                    return completion(true, dict)
                } else {
                    pastData = data
                    completion(true, dict)
                }
            }
        }

        Self.request(url: url, method: method, headers: headers, json: json) { success, data in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                try? data.write(to: path)
            }
            if pastData == data { return }
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] ?? [String: Any]()
                return completion(true, dict)
            } catch {}
            return completion(false, nil)
        }
    }
    
    class public func array(request: URLRequest, cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ array: [[String: Any]]?) -> Void)) {
        var pastData: Data?
        if cache {
            if let url = request.url {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                if let data = try? Data(contentsOf: path),
                   let arr = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] {
                    if skipNetwork(path) {
                        return completion(true, arr)
                    } else {
                        pastData = data
                        completion(true, arr)
                    }
                }
            }
        }
        Self.request(request) { success, data in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                if let url = request.url {
                    let encoded = url.absoluteString.toBase64
                    let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                    try? data.write(to: path)
                }
            }
            if pastData == data { return }
            do {
                let arr = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] ?? [[String: Any]]()
                return completion(true, arr)
            } catch {}
            return completion(false, nil)
        }
    }
    
    class public func array(url: String?, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ array: [[String: Any]]?) -> Void)) {
        guard let surl = url,
              let url = URL(string: surl) else { return completion(false, nil) }
        Self.array(url: url, method: method, headers: headers, json: json, cache: cache) { success, array -> Void in
            return completion(success, array)
        }
    }
    
    class public func array(url: URL, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ array: [[String: Any]]?) -> Void)) {
        var pastData: Data?
        if cache {
            let encoded = url.absoluteString.toBase64
            let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
            if let data = try? Data(contentsOf: path),
               let arr = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] {
                if skipNetwork(path) {
                    return completion(true, arr)
                } else {
                    pastData = data
                    completion(true, arr)
                }
            }
        }
        Self.request(url: url, method: method, headers: headers, json: json) { success, data in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                try? data.write(to: path)
            }
            if pastData == data { return }
            do {
                let arr = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] ?? [[String: Any]]()
                return completion(true, arr)
            } catch {}
            return completion(false, nil)
        }
    }
    
    class public func data(request: URLRequest, cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        var pastData: Data?
        if cache {
            if let url = request.url {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                if let data = try? Data(contentsOf: path) {
                    if skipNetwork(path) {
                        return completion(true, data)
                    } else {
                        pastData = data
                        completion(true, data)
                    }
                }
            }
        }
        Self.request(request) { success, data in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                if let url = request.url {
                    let encoded = url.absoluteString.toBase64
                    let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                    try? data.write(to: path)
                }
            }
            if pastData == data { return }
            completion(true, data)
        }
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
    
    class public func data(url: String?, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        guard let surl = url,
              let url = URL(string: surl) else { return completion(false, nil) }
        Self.data(url: url, method: method, headers: headers, json: json, cache: cache) { success, data -> Void in
            return completion(success, data)
        }
    }
    
    class public func data(url: URL, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], cache: Bool = false, _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        var pastData: Data?
        if cache {
            let encoded = url.absoluteString.toBase64
            let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
            if let data = try? Data(contentsOf: path) {
                if skipNetwork(path) {
                    return completion(true, data)
                } else {
                    pastData = data
                    completion(true, data)
                }
            }
        }
        Self.request(url: url, method: method, headers: headers, json: json) { success, data in
            guard success,
                  let data = data else { return completion(false, nil) }
            if cache {
                let encoded = url.absoluteString.toBase64
                let path = Self.shared.cacheDirectory.appendingPathComponent("\(encoded).json")
                try? data.write(to: path)
            }
            if pastData == data { return }
            completion(true, data)
        }
    }
    
    class private func request(url: URL, method: String = "GET", headers: [String: String] = [:], json: [String: AnyHashable] = [:], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if !json.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            request.httpBody = jsonData
            request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        let task = URLSession.shared.dataTask(with: request) { data, _, _ -> Void in
            if let data = data {
                return completion(true, data)
            }
            return completion(false, nil)
        }
        task.resume()
    }
    
    class private func request(_ request: URLRequest, _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        let task = URLSession.shared.dataTask(with: request) { data, _, _ -> Void in
            if let data = data {
                return completion(true, data)
            }
            return completion(false, nil)
        }
        task.resume()
    }
    
    public func image(_ url: String, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        guard let url = URL(string: url) else { return nil }
        return self.image(url, method: method, headers: headers, cache: cache, scale: scale, size: size) { refresh, image in
            completion?(refresh, image)
        }
    }
    
    public func image(_ url: URL, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return nil
        }
        var pastData: Data?
        let encoded = url.absoluteString.toBase64
        if cache,
           let image = memoryCache.object(forKey: encoded as NSString) {
            return image
        }
        let path = cacheDirectory.appendingPathComponent("\(encoded).png")
        if path.exists {
            if let data = try? Data(contentsOf: path) {
                if var image = (scale != nil) ? UIImage(data: data, scale: scale!) : UIImage(data: data) {
                    if let downscaled = ImageProcessing.downsample(image: image, to: size, scale: scale) {
                        image = downscaled
                    }
                    if cache {
                        memoryCache.setObject(image, forKey: encoded as NSString)
                        pastData = data
                        if Self.skipNetwork(path) {
                            return image
                        } else {
                            completion?(true, image)
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
               var image = (scale != nil) ? UIImage(data: data, scale: scale!) : UIImage(data: data) {
                if let downscaled = ImageProcessing.downsample(image: image, to: size, scale: scale) {
                    image = downscaled
                }
                completion?(pastData != data, image)
                if cache {
                    memoryCache.setObject(image, forKey: encoded as NSString)
                    do {
                        try data.write(to: path, options: .atomic)
                    } catch {
                        print("Error saving to \(path.absoluteString) with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        task.resume()
        return nil
    }
    
    public func gif(_ url: String, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        guard let url = URL(string: url) else { return nil }
        return self.gif(url, method: method, headers: headers, cache: cache, scale: scale, size: size, completion)
    }
    
    public func gif(_ url: URL, method: String = "GET", headers: [String: String] = [:], cache: Bool = true, scale: CGFloat? = nil, size: CGSize? = nil, _ completion: ((_ refresh: Bool, _ image: UIImage?) -> Void)?) -> UIImage? {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return nil
        }
        var pastData: Data?
        let encoded = url.absoluteString.toBase64
        if cache,
           let image = memoryCache.object(forKey: encoded as NSString) {
            return image
        }
        let path = cacheDirectory.appendingPathComponent("\(encoded).gif")
        if path.exists {
            if let data = try? Data(contentsOf: path) {
                if let image = EvanderGIF(data: data, size: size, scale: scale) {
                    if cache {
                        memoryCache.setObject(image, forKey: encoded as NSString)
                        pastData = data
                        if Self.skipNetwork(path) {
                            return image
                        } else {
                            completion?(true, image)
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
                        try data.write(to: path, options: .atomic)
                    } catch {
                        print("Error saving to \(path.absoluteString) with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        task.resume()
        return nil
    }
    
    public func saveCache(_ url: URL, data: Data) {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return
        }
        let encoded = url.absoluteString.toBase64
        let path = cacheDirectory.appendingPathComponent("\(encoded).png")
        do {
            try data.write(to: path, options: .atomic)
        } catch {
            print("Error saving to \(path.absoluteString) with error: \(error.localizedDescription)")
        }
    }
    
    public func imageCache(_ url: URL, scale: CGFloat? = nil, size: CGSize? = nil) -> (Bool, UIImage?) {
        if String(url.absoluteString.prefix(7)) == "file://" {
            return (true, nil)
        }
        let encoded = url.absoluteString.toBase64
        let path = cacheDirectory.appendingPathComponent("\(encoded).png")
        if let memory = memoryCache.object(forKey: encoded as NSString) {
            return (!Self.skipNetwork(path), memory)
        }
        if let data = try? Data(contentsOf: path) {
            if var image = (scale != nil) ? UIImage(data: data, scale: scale!) : UIImage(data: data) {
                if let downscaled = ImageProcessing.downsample(image: image, to: size, scale: scale) {
                    image = downscaled
                }
                return (!Self.skipNetwork(path), image)
            }
        }
        return (true, nil)
    }
}



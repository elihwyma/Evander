//  Created by Amy on 01/05/2021.
//  Copyright © 2021 Amy While. All rights reserved.
//

import Foundation

final public class EvanderDownloader: NSObject {
    
    static let sessionManager: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration, delegate: EvanderDownloadDelegate.shared, delegateQueue: OperationQueue())
    }()
    
    static let config = URLSessionConfiguration.default
    
    private var request: URLRequest
    private var task: URLSessionDownloadTask?
    private let queue = OperationQueue()
    private var progress = DownloadProgress()
    private var killed = false
    
    public var progressCallback: ((_ progress: DownloadProgress) -> Void)? {
        didSet {
            container?.progressCallback = progressCallback
        }
    }
    public var didFinishCallback: ((_ status: Int, _ url: URL) -> Void)? {
        didSet {
            container?.didFinishCallback = didFinishCallback
        }
    }
    public var errorCallback: ((_ status: Int, _ error: Error?, _ url: URL?) -> Void)? {
        didSet {
            container?.errorCallback = errorCallback
        }
    }
    public var waitingCallback: ((_ message: String) -> Void)? {
        didSet {
            container?.waitingCallback = waitingCallback
        }
    }

    public var url: URL? { request.url }
    public var hasRetried = false
    public var container: EvanderDownloadContainer? {
        guard let url = url,
              let container = EvanderDownloadDelegate.shared.containers[url] else { return nil }
        return container
    }

    public init(url: URL, method: String = "GET", headers: [String: String] = [:]) {
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        self.request = request
        super.init()
        let container = EvanderDownloadContainer(url: url)
        EvanderDownloadDelegate.shared.containers[url] = container
    }
    
    public init?(request: URLRequest) {
        self.request = request
        guard let url = request.url else { return nil }
        super.init()
        let container = EvanderDownloadContainer(url: url)
        EvanderDownloadDelegate.shared.containers[url] = container
    }
    
    public func cancel() {
        killed = true
        task?.cancel()
        guard let url = url else { return }
        EvanderDownloadDelegate.shared.containers[url] = nil
    }
    
    public func resume() {
        task?.resume()
    }

    public func make() {
        let task = EvanderDownloader.sessionManager.downloadTask(with: request)
        self.task = task
    }
    
}

final public class EvanderDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    static public let shared = EvanderDownloadDelegate()
    
    public lazy var containers: SafeDictionary = SafeDictionary<URL, EvanderDownloadContainer>(queue: queue, key: queueKey, context: queueContext)
    private lazy var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "AmyDownloadParserDelegate.ContainerQueue",
                                  attributes: .concurrent)
        queue.setSpecific(key: queueKey, value: queueContext)
        return queue
    }()
    private let queueKey = DispatchSpecificKey<Int>()
    public let queueContext = 50

    public func terminate(_ url: URL) {
        containers[url]?.toBeTerminated = true
    }
    
    // The Download Finished
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.response?.url ?? downloadTask.currentRequest?.url,
              let container = containers[url] else { return }
        defer {
            containers[url] = nil
        }
        if container.toBeTerminated {
            downloadTask.cancel()
            return
        }
        let filename = location.lastPathComponent,
            destination = EvanderNetworking.shared.downloadCache.appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            container.errorCallback?(522, error, destination)
        }

        if let response = downloadTask.response,
           let statusCode = (response as? HTTPURLResponse)?.statusCode {
            if statusCode == 200 || statusCode == 206 { // 206 means partial data, APT handles it fine
                container.didFinishCallback?(statusCode, destination)
            } else {
                container.errorCallback?(statusCode, nil, destination)
            }
            return
        }
        if !container.killed {
            container.errorCallback?(522, nil, destination)
        }
    }
    
    // The Download has made Progress
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.response?.url ?? downloadTask.currentRequest?.url,
              let container = containers[url] else { return }
        if container.toBeTerminated {
            containers[url] = nil
            downloadTask.cancel()
            return
        }
        container.progress.period = bytesWritten
        container.progress.total = totalBytesWritten
        container.progress.expected = totalBytesExpectedToWrite
        container.progressCallback?(container.progress)
    }
    
    // Checking for errors in the download
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.response?.url ?? task.currentRequest?.url,
              let container = containers[url] else { return }
        if container.toBeTerminated {
            containers[url] = nil
            task.cancel()
            return
        }
        if let error = error {
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 522
            container.errorCallback?(statusCode, error, nil)
        }
    }
    
    // Tell the caller that the download is waiting for network
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        guard let url = task.response?.url,
              let container = containers[url] else { return }
        container.waitingCallback?("Waiting For Connection")
    }
    
    // The Download started again with some progress
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let url = downloadTask.response?.url,
              let container = containers[url] else { return }
        if container.toBeTerminated {
            containers[url] = nil
            downloadTask.cancel()
            return
        }
        container.progress.period = 0
        container.progress.total = fileOffset
        container.progress.expected = expectedTotalBytes
        container.progressCallback?(container.progress)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        defer {
            completionHandler(request)
        }
        guard let url = task.currentRequest?.url,
              let container = containers[url],
              let newURL = request.url else {
            return
        }
        container.url = newURL
        containers[newURL] = container
        containers[url] = nil
    }
}

public class EvanderDownloadContainer {
    public var url: URL
    public var progress = DownloadProgress()
    public var killed = false
    public var progressCallback: ((_ progress: DownloadProgress) -> Void)?
    public var didFinishCallback: ((_ status: Int, _ url: URL) -> Void)?
    public var errorCallback: ((_ status: Int, _ error: Error?, _ url: URL?) -> Void)?
    public var waitingCallback: ((_ message: String) -> Void)?
    
    public var toBeTerminated = false
    
    public init(url: URL) {
        self.url = url
    }
}

public struct DownloadProgress {
    public var period: Int64 = 0
    public var total: Int64 = 0
    public var expected: Int64 = 0
    public var fractionCompleted: Double {
        Double(total) / Double(expected)
    }
}

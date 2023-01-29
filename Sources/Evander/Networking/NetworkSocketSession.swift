//
//  NetworkSocketSession.swift
//  Medusa
//
//  Created by Amy While on 06/10/2022.
//

import Foundation

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
public class NetworkSocketSession: NSObject {
    
    private let configuration: NetworkSessionConfig
    private lazy var session: URLSession = {
        URLSession(configuration: configuration.sessionConfiguration, delegate: self, delegateQueue: OperationQueue())
    }()
    
    private var task: URLSessionWebSocketTask?
    private weak var delegate: NetworkSocketDelegate?
    
    public init(configuration: NetworkSessionConfig, delegate: NetworkSocketDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        
        super.init()
    }
    
    public func start(url: URL) {
        let task = session.webSocketTask(with: url)
        task.resume()
        self.task = task
        receive()
    }
    
    private func receive() {
        guard let task = task else { return }
        task.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    self?.delegate?.didReceiveString(string: string)
                case .data(let data):
                    self?.delegate?.didReceiveData(data: data)
                @unknown default:
                    break
                }
            case .failure:
                self?.task?.cancel()
            }
            self?.receive()
        }
    }
    
    public func send(data: Data) {
        task?.send(.data(data), completionHandler: { [weak self] error in
            if error != nil {
                self?.task?.cancel()
            }
        })
    }
    
    public func send(string: String) {
        task?.send(.string(string), completionHandler: { [weak self] error in
            if error != nil {
                self?.task?.cancel()
            }
        })
    }
    
}

@available(iOS 13, macOS 10.15, watchOS 5, tvOS 13, *)
extension NetworkSocketSession: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol: String?) {
        delegate?.didOpen()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        delegate?.didCloseWithCode(code: didCloseWith, reason: reason)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        delegate?.didCloseWithError(error: error)
    }
    
}

//
//  StreamProducerType.swift
//  RMComponents
//
//  Created by Anthony on 15/11/25.
//

import Foundation

public protocol StreamProducerType: Actor {
    
    associatedtype Element: Sendable
    
    var withLatest: Bool { get }
    var stream: AsyncStream<Element> { get }
    
    func emit(element: Element)
    func finish()
    nonisolated func nonIsolatedFinish()
}

public actor StreamProducer<Element>: StreamProducerType where Element: Sendable {
    
    typealias Continuation = AsyncStream<Element>.Continuation
    
    private let storage = StreamStorage()
    private var latestElement: Element?
    
    public let withLatest: Bool
    
    /// Events stream
    public var stream: AsyncStream<Element> {
        AsyncStream { continuation in
            if let latestElement, withLatest {
                continuation.yield(latestElement)
            }
            append(continuation)
        }
    }
    
    public init(element: Element? = nil, withLatest: Bool = true) {
        self.withLatest = withLatest
        self.latestElement = element
    }
    
    public func emit(element: Element) {
        if withLatest {
            latestElement = element
        }
        storage.emit(element: element)
    }

    public func finish() {
        storage.finish()
    }
    
    private func append(_ continuation: Continuation) {
        let key = UUID().uuidString
        continuation.onTermination  = {[weak self] _ in
            self?.onTermination(forKey: key)
        }
        storage.update(continuation, forKey: key)
    }
    
    private func removeContinuation(forKey key: String) {
        storage.removeContinuation(forKey: key)
    }

    nonisolated private func onTermination(forKey key: String) {
        if #available(iOS 26.0, macOS 26.0, *) {
            Task.immediate {
                await removeContinuation(forKey: key)
            }
        } else {
            Task(priority: .high) {
                await removeContinuation(forKey: key)
            }
        }
    }
    
    @available(*, deprecated, renamed: "finish", message: "The Stream will be automatically finished when deallocated. No need to call it manually.")
    public nonisolated func nonIsolatedFinish() {
        if #available(iOS 26.0, macOS 26.0, *) {
            Task.immediate {
                await finish()
            }
        } else {
            Task(priority: .high) {
                await finish()
            }
        }
    }
    
    public nonisolated func nonIsolatedEmit(_ element: Element) {
        if #available(iOS 26.0, macOS 26.0, *) {
            Task.immediate {
                await emit(element: element)
            }
        } else {
            Task(priority: .high) {
                await emit(element: element)
            }
        }
    }
}

//MARK: - Storage
extension StreamProducer {
    private final class StreamStorage {
        
        private var continuations: [String:Continuation] = [:]
        
        func emit(element: Element) {
            continuations.values.forEach({ $0.yield(element) })
        }
        
        func update(_ continuation: Continuation, forKey key: String) {
            continuations.updateValue(continuation, forKey: key)
        }
        
        func removeContinuation(forKey key: String) {
            continuations.removeValue(forKey: key)
        }
        
        func finish() {
            continuations.values.forEach({ $0.finish() })
            continuations.removeAll()
        }
        
        deinit {
            finish()
        }
    }
}


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
    
    public let withLatest: Bool
    private var continuations: [String:Continuation] = [:]
    private var latestElement: Element?
    
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
        continuations.values.forEach({ $0.yield(element) })
    }

    public func finish() {
        continuations.values.forEach({ $0.finish() })
        continuations.removeAll()
    }
    
    private func append(_ continuation: Continuation) {
        let key = UUID().uuidString
        continuation.onTermination  = {[weak self] _ in
            self?.onTermination(forKey: key)
        }
        continuations.updateValue(continuation, forKey: key)
    }
    
    private func removeContinuation(forKey key: String) {
        continuations.removeValue(forKey: key)
    }

    nonisolated private func onTermination(forKey key: String) {
        Task(priority: .high) {
            await removeContinuation(forKey: key)
        }
    }
    
    public nonisolated func nonIsolatedFinish() {
        Task(priority: .high) {
            await finish()
        }
    }
    
    public nonisolated func nonIsolatedEmit(_ element: Element) {
        Task(priority: .high) {
            await emit(element: element)
        }
    }
}

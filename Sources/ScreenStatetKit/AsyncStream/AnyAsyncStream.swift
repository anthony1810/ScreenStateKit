//
//  AnyAsyncStream.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//
import Foundation

/// A type-erased async sequence that wraps any async sequence with the same element type
public struct AnyAsyncStream<Element>: AsyncSequence, AsyncIteratorProtocol {
    private var interator: any AsyncIteratorProtocol

    public init<Base>(_ base: Base) where Base: AsyncSequence, Base.Element == Element {
        self.interator = base.makeAsyncIterator()
    }

    mutating public func next() async throws -> Element? {
        try Task.checkCancellation()
        guard let value = try await interator.next() else {
            return nil
        }
        guard let element = value as? Element else {
            return nil
        }
        return element
    }

    @available(iOS 18.0, macOS 15.0, *)
    mutating public func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
        try Task.checkCancellation()
        guard let value = try await interator.next(isolation: actor) else {
            return nil
        }
        guard let element = value as? Element else {
            return nil
        }
        return element
    }
    
    public func makeAsyncIterator() -> Self {
        self
    }
}

extension AnyAsyncStream: @unchecked Sendable
where AsyncIterator: Sendable, Element: Sendable { }

extension AsyncSequence {
    public var anyAsyncStream: AnyAsyncStream<Element> {
        .init(self)
    }
}

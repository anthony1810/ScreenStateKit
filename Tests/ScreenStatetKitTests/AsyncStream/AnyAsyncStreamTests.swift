//
//  AnyAsyncStreamTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("AnyAsyncStream Tests")
struct AnyAsyncStreamTests {

    // MARK: - Type Erasure Tests

    @Test("wraps AsyncStream and iterates elements")
    func test_wrapsAsyncStream_iteratesElements() async throws {
        let stream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let sut = AnyAsyncStream(stream)

        var received: [Int] = []
        for try await element in sut {
            received.append(element)
        }

        #expect(received == [1, 2, 3])
    }
}

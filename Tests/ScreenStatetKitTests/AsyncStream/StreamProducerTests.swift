//
//  StreamProducerTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("StreamProducer Tests")
struct StreamProducerTests {
    
    // MARK: - emit() Tests
    
    @Test("emit delivers element to subscriber")
    func test_emit_deliversToSubscriber() async {
        let sut = StreamProducer<Int>(withLatest: false)
        
        Task {
            try await Task.sleep(for: .milliseconds(50))
            await sut.emit(element: 42)
            await sut.finish()
        }
        
        var received: Int?
        for await element in await sut.stream {
            received = element
        }

        #expect(received == 42)
    }

    @Test("withLatest true emits latest element to new subscriber")
    func test_withLatestTrue_emitsLatestToNewSubscriber() async {
        let sut = StreamProducer<Int>(withLatest: true)

        // Emit multiple elements before subscribing
        await sut.emit(element: 1)
        await sut.emit(element: 2)
        await sut.emit(element: 99)

        // New subscriber should receive the latest (99), not all previous
        var received: Int?
        for await element in await sut.stream {
            received = element
            break
        }

        #expect(received == 99)
    }
}

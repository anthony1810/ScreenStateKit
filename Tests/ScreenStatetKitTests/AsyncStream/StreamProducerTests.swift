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
            break
        }
        
        #expect(received == 42)
    }
}

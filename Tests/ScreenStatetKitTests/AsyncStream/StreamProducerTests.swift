//
//  StreamProducerTests.swift
//  ScreenStatetKit
//

import Testing
import ConcurrencyExtras
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

    @Test("emit delivers element to multiple subscribers")
    func test_emit_deliversToMultipleSubscribers() async {
        await withMainSerialExecutor {
            let sut = StreamProducer<Int>(withLatest: false)

            let received1 = LockIsolated<[Int]>([])
            let received2 = LockIsolated<[Int]>([])

            let task1 = Task {
                for await element in await sut.stream {
                    received1.withValue { $0.append(element) }
                }
            }

            let task2 = Task {
                for await element in await sut.stream {
                    received2.withValue { $0.append(element) }
                }
            }

            await Task.yield()

            await sut.emit(element: 10)
            await sut.emit(element: 20)
            await sut.finish()

            await task1.value
            await task2.value

            #expect(received1.value == [10, 20])
            #expect(received2.value == [10, 20])
        }
    }

    // MARK: - withLatest Tests

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

    // MARK: - finish() Tests

    @Test("finish terminates all streams")
    func test_finish_terminatesAllStreams() async {
        await withMainSerialExecutor {
            let sut = StreamProducer<Int>(withLatest: false)

            let task1Finished = LockIsolated(false)
            let task2Finished = LockIsolated(false)

            let task1 = Task {
                for await _ in await sut.stream { }
                task1Finished.setValue(true)
            }

            let task2 = Task {
                for await _ in await sut.stream { }
                task2Finished.setValue(true)
            }

            await Task.yield()
            await sut.finish()

            await task1.value
            await task2.value

            #expect(task1Finished.value == true)
            #expect(task2Finished.value == true)
        }
    }
}

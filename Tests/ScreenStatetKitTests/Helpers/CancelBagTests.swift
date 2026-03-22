//
//  CancelBagTests.swift
//  ScreenStatetKit
//

import Testing
import ConcurrencyExtras
@testable import ScreenStateKit

@Suite("CancelBag Tests")
struct CancelBagTests {

    // MARK: - cancelAll() Tests

    @Test("cancelAll cancels all stored tasks")
    func test_cancelAll_cancelsAllStoredTasks() async throws {
        await withMainSerialExecutor {
            let sut = CancelBag(onDuplicate: .cancelExisting)

            let task1 = Task {
                try await Task.sleep(for: .seconds(10))
            }
            let task2 = Task {
                try await Task.sleep(for: .seconds(10))
            }

            task1.store(in: sut)
            task2.store(in: sut)

            await Task.megaYield()

            await sut.cancelAll()

            #expect(task1.isCancelled == true)
            #expect(task2.isCancelled == true)
        }
    }

    // MARK: - cancel(forIdentifier:) Tests

    @Test("cancel for identifier cancels specific task")
    func test_cancelForIdentifier_cancelsSpecificTask() async throws {
        await withMainSerialExecutor {
            let sut = CancelBag(onDuplicate: .cancelExisting)

            let task1 = Task {
                try await Task.sleep(for: .seconds(10))
            }
            let task2 = Task {
                try await Task.sleep(for: .seconds(10))
            }

            task1.store(in: sut, withIdentifier: "task1")
            task2.store(in: sut, withIdentifier: "task2")

            await Task.megaYield()

            await sut.cancel(forIdentifier: "task1")

            #expect(task1.isCancelled == true)
            #expect(task2.isCancelled == false)
        }
    }

    // MARK: - store() Tests

    @Test("store with same identifier cancels previous task")
    func test_store_withSameIdentifierCancelsPreviousTask() async throws {
        await withMainSerialExecutor {
            let sut = CancelBag(onDuplicate: .cancelExisting)

            let task1 = Task {
                try await Task.sleep(for: .seconds(10))
            }
            let task2 = Task {
                try await Task.sleep(for: .seconds(10))
            }

            task1.store(in: sut, withIdentifier: "sameId")

            await Task.megaYield()

            task2.store(in: sut, withIdentifier: "sameId")

            await Task.megaYield()

            #expect(task1.isCancelled == true)
            #expect(task2.isCancelled == false)
        }
    }

    @Test("store with same identifier cancels new task")
    func test_store_withSameIdentifierCancelsNewTask() async throws {
        await withMainSerialExecutor {
            let sut = CancelBag(onDuplicate: .cancelNew)

            let task1 = Task {
                try await Task.sleep(for: .seconds(10))
            }
            let task2 = Task {
                try await Task.sleep(for: .seconds(10))
            }

            task1.store(in: sut, withIdentifier: "sameId")

            await Task.megaYield()

            task2.store(in: sut, withIdentifier: "sameId")

            await Task.megaYield()

            #expect(task1.isCancelled == false)
            #expect(task2.isCancelled == true)
        }
    }

    @Test("watch task completed should remove it from cancelbag storage")
    func testWatchTaskCompletedRemoveCancellerFromStorage() async throws {
        await withMainSerialExecutor {
            let sut = CancelBag(onDuplicate: .cancelExisting)

            Task { }.store(in: sut)

            Task {
                try await Task.sleep(for: .seconds(10))
            }.store(in: sut)

            await Task.megaYield()

            let count = await sut.count
            let isEmpty = await sut.isEmpty

            #expect(count == 1)
            #expect(isEmpty == false)
        }
    }
}

// MARK: - Helpers

extension CancelBagTests {
    private func makeSUT() -> CancelBag {
        CancelBag(onDuplicate: .cancelExisting)
    }
}

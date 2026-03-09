//
//  CancelBagTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("CancelBag Tests")
struct CancelBagTests {

    // MARK: - cancelAll() Tests

    @Test("cancelAll cancels all stored tasks")
    func test_cancelAll_cancelsAllStoredTasks() async throws {
        let sut = CancelBag(duplicate: .cancelExisting)

        let task1 = Task {
            try await Task.sleep(for: .seconds(10))
        }
        let task2 = Task {
            try await Task.sleep(for: .seconds(10))
        }

        task1.store(in: sut)
        task2.store(in: sut)

        try await Task.sleep(for: .milliseconds(50))

        await sut.cancelAll()

        try await Task.sleep(for: .milliseconds(50))

        #expect(task1.isCancelled == true)
        #expect(task2.isCancelled == true)
    }

    // MARK: - cancel(forIdentifier:) Tests

    @Test("cancel for identifier cancels specific task")
    func test_cancelForIdentifier_cancelsSpecificTask() async throws {
        let sut = CancelBag(duplicate: .cancelExisting)

        let task1 = Task {
            try await Task.sleep(for: .seconds(10))
        }
        let task2 = Task {
            try await Task.sleep(for: .seconds(10))
        }

        task1.store(in: sut, withIdentifier: "task1")
        task2.store(in: sut, withIdentifier: "task2")

        try await Task.sleep(for: .milliseconds(50))

        await sut.cancel(forIdentifier: "task1")

        try await Task.sleep(for: .milliseconds(50))

        #expect(task1.isCancelled == true)
        #expect(task2.isCancelled == false)
    }

    // MARK: - store() Tests

    @Test("store with same identifier cancels previous task")
    func test_store_withSameIdentifierCancelsPreviousTask() async throws {
        let sut = CancelBag(duplicate: .cancelExisting)

        let task1 = Task {
            try await Task.sleep(for: .seconds(10))
        }
        let task2 = Task {
            try await Task.sleep(for: .seconds(10))
        }

        task1.store(in: sut, withIdentifier: "sameId")

        try await Task.sleep(for: .milliseconds(50))

        task2.store(in: sut, withIdentifier: "sameId")

        try await Task.sleep(for: .milliseconds(50))

        #expect(task1.isCancelled == true)
        #expect(task2.isCancelled == false)
    }
    
    @Test("watch task is copmpleted should remove it from cancelbag storage")
    func testWatchTaskCompletedRemoveCancellerFromStorage() async throws {
        let sut = CancelBag(duplicate: .cancelExisting)

        Task {
            try await Task.sleep(for: .milliseconds(10))
        }.store(in: sut)
        
        Task {
            try await Task.sleep(for: .seconds(10))
        }.store(in: sut)
        
        try await Task.sleep(for: .milliseconds(50))
        
        let count = await sut.count
        let isEmpty = await sut.isEmpty
        
        #expect(count == 1)
        #expect(isEmpty == false)
    }
}

// MARK: - Helpers

extension CancelBagTests {
    private func makeSUT() -> CancelBag {
        CancelBag(duplicate: .cancelExisting)
    }
}

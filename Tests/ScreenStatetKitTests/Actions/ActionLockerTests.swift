//
//  ActionLockerTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("ActionLocker Tests")
struct ActionLockerTests {
    
    // MARK: - lock() Tests

    @Test("lock throws error when action is already locked")
    func test_lock_deliversErrorOnAlreadyLockedAction() async throws {
        let sut = makeSUT()
        let action = TestAction.fetch

        try await sut.lock(action)

        await #expect(throws: ActionLocker.Errors.actionIsRunning) {
            try await sut.lock(action)
        }
    }

    @Test("lock succeeds for new action")
    func test_lock_succeedsForNewAction() async throws {
        let sut = makeSUT()

        try await sut.lock(TestAction.fetch)
    }

    // MARK: - unlock() Tests

    @Test("unlock releases locked action allowing it to be locked again")
    func test_unlock_releasesLockedAction() async throws {
        let sut = makeSUT()
        let action = TestAction.fetch

        try await sut.lock(action)
        await sut.unlock(action)

        try await sut.lock(action)
    }

    // MARK: - canExecute() Tests

    @Test("canExecute returns true and locks for new action")
    func test_canExecute_returnsTrueAndLocksForNewAction() async {
        let sut = makeSUT()
        let action = TestAction.fetch

        let result = await sut.canExecute(action)
        #expect(result == true)

        let secondResult = await sut.canExecute(action)
        #expect(secondResult == false)
    }

    @Test("canExecute returns false for already locked action")
    func test_canExecute_returnsFalseForAlreadyLockedAction() async throws {
        let sut = makeSUT()
        let action = TestAction.fetch

        try await sut.lock(action)

        let result = await sut.canExecute(action)

        #expect(result == false)
    }

    // MARK: - free() Tests

    @Test("free clears all locks")
    func test_free_clearsAllLocks() async throws {
        let sut = makeSUT()

        try await sut.lock(TestAction.fetch)
        try await sut.lock(TestAction.loadMore)

        await sut.free()

        let canExecuteFetch = await sut.canExecute(TestAction.fetch)
        let canExecuteLoadMore = await sut.canExecute(TestAction.loadMore)

        #expect(canExecuteFetch == true)
        #expect(canExecuteLoadMore == true)
    }
}
// MARK: - Helpers

extension ActionLockerTests {
    private enum TestAction: ActionLockable {
        case fetch
        case loadMore
    }

    private func makeSUT() -> ActionLocker {
        ActionLocker()
    }
}

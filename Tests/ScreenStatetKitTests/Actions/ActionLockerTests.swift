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

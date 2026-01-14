//
//  ActionLockableTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("ActionLockable Tests")
struct ActionLockableTests {

    // MARK: - lockkey Tests

    @Test("lockkey generates from type description")
    func test_lockkey_generatesFromTypeDescription() {
        let action = TestAction.fetch

        #expect(action.lockkey == "fetch")
    }
}

// MARK: - Helpers

extension ActionLockableTests {
    private enum TestAction: ActionLockable {
        case fetch
        case loadMore
    }
}

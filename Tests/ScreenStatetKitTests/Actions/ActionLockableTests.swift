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

    @Test("lockkey distinguishes different enum cases")
    func test_lockkey_distinguishesDifferentEnumCases() {
        let fetchAction = TestAction.fetch
        let loadMoreAction = TestAction.loadMore

        #expect(fetchAction.lockkey != loadMoreAction.lockkey)
        #expect(fetchAction.lockkey == "fetch")
        #expect(loadMoreAction.lockkey == "loadMore")
    }
}

// MARK: - Helpers

extension ActionLockableTests {
    private enum TestAction: ActionLockable {
        case fetch
        case loadMore
    }
}

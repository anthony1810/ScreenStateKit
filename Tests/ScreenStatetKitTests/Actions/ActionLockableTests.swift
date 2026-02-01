//
//  ActionLockableTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("ActionLockable Tests")
struct ActionLockableTests {

    // MARK: - lockkey Tests

    @Test("lockkey same action yields same key")
    func test_lockkey_generatesFromTypeDescription() {
        let action = TestAction.fetch
        let sameAction = TestAction.fetch
        
        #expect(action.lockKey == sameAction.lockKey)
    }

    @Test("lockkey distinguishes different enum cases")
    func test_lockkey_distinguishesDifferentEnumCases() {
        let fetchAction = TestAction.fetch
        let loadMoreAction = TestAction.loadMore

        #expect(fetchAction.lockKey != loadMoreAction.lockKey)
    }
    
    @Test("lockey by enum parametters")
    func test_LockeyWithEnumParameters() {
        let readAction1 = TestAction.read(byId: 1)
        let readAction2 = TestAction.read(byId: 2)
        let readActionSame1 = TestAction.read(byId: 1)
        
        #expect(readAction1.lockKey != readAction2.lockKey)
        #expect(readAction1.lockKey == readActionSame1.lockKey)
    }
}

// MARK: - Helpers

extension ActionLockableTests {
    private enum TestAction: ActionLockable, Hashable {
        case fetch
        case loadMore
        case read(byId: Int)
    }
}

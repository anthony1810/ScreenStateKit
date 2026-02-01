//
//  StateKeyPathUpdatableTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("StateUpdatable Tests")
@MainActor
struct StateUpdatableTests {

    // MARK: - updateState() Tests

    @Test("updateState updates single keypath value")
    func test_updateState_updatesSingleKeyPath() {
        let sut = TestState()
        sut.updateState({ state in
            state.name = "Updated"
        })

        #expect(sut.name == "Updated")
    }

    @Test("updateState updates multiple keypath values atomically")
    func test_updateState_updatesMultipleKeyPaths() {
        let sut = TestState()
        sut.updateState { state in
            state.name = "New Name"
            state.count = 42
        }
        #expect(sut.name == "New Name")
        #expect(sut.count == 42)
    }
}

// MARK: - Helpers

extension StateUpdatableTests {
    @MainActor
    private final class TestState: StateUpdatable {
        var name: String = ""
        var count: Int = 0
    }
}

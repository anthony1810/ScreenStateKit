//
//  StateKeyPathUpdatableTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("StateKeyPathUpdatable Tests")
@MainActor
struct StateKeyPathUpdatableTests {

    // MARK: - updateState() Tests

    @Test("updateState updates single keypath value")
    func test_updateState_updatesSingleKeyPath() {
        let sut = TestState()

        sut.updateState(StateUpdater(keypath: \.name, value: "Updated"))

        #expect(sut.name == "Updated")
    }

    @Test("updateState updates multiple keypath values atomically")
    func test_updateState_updatesMultipleKeyPaths() {
        let sut = TestState()

        sut.updateState(
            StateUpdater(keypath: \.name, value: "New Name"),
            StateUpdater(keypath: \.count, value: 42)
        )

        #expect(sut.name == "New Name")
        #expect(sut.count == 42)
    }
}

// MARK: - Helpers

extension StateKeyPathUpdatableTests {
    @MainActor
    private final class TestState: StateKeyPathUpdatable {
        var name: String = ""
        var count: Int = 0
    }
}

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

    // MARK: - readState() Tests

    @Test("readState returns a single value")
    func test_readState_returnsSingleValue() {
        let sut = TestState()
        sut.name = "Solo"

        let name: String = sut.readState { state in
            state.name
        }

        #expect(name == "Solo")
    }

    @Test("readState returns a tuple of multiple values")
    func test_readState_returnsTupleOfMultipleValues() {
        let sut = TestState()
        sut.name = "Multi"
        sut.count = 7

        let values: (String, Int) = sut.readState { state in
            state.name
            state.count
        }

        #expect(values.0 == "Multi")
        #expect(values.1 == 7)
    }

    @Test("readState returns a tuple preserving order and arity")
    func test_readState_returnsTuplePreservingArity() {
        let sut = TestState()
        sut.name = "Triple"
        sut.count = 3

        let values: (String, Int, Bool) = sut.readState { state in
            state.name
            state.count
            state.count > 0
        }

        #expect(values.0 == "Triple")
        #expect(values.1 == 3)
        #expect(values.2 == true)
    }

    @Test("readState reflects values mutated via updateState")
    func test_readState_reflectsUpdatedState() {
        let sut = TestState()
        sut.updateState { state in
            state.name = "Fresh"
            state.count = 99
        }

        let values: (String, Int) = sut.readState { state in
            state.name
            state.count
        }

        #expect(values.0 == "Fresh")
        #expect(values.1 == 99)
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

//
//  AsyncActionTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("AsyncAction Tests")
struct AsyncActionTests {

    // MARK: - asyncExecute() Tests

    @Test("asyncExecute executes wrapped action and returns output")
    func test_asyncExecute_executesWrappedActionAndReturnsOutput() async throws {
        let sut = AsyncActionGet<Int> {
            return 42
        }

        let result = try await sut.asyncExecute()

        #expect(result == 42)
    }

    // MARK: - Hashable Tests

    @Test("different instances are not equal")
    func test_hashable_differentInstancesAreNotEqual() {
        let action1 = AsyncActionVoid { }
        let action2 = AsyncActionVoid { }

        #expect(action1 != action2)
    }
}

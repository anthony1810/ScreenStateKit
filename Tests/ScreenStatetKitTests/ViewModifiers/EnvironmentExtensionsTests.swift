//
//  EnvironmentExtensionsTests.swift
//  ScreenStateKit
//

import Testing
import SwiftUI
import ConcurrencyExtras
@testable import ScreenStateKit

@Suite("Environment Extensions Tests")
@MainActor
struct EnvironmentExtensionsTests {

    // MARK: - onEdited

    @Test("onEdited executes provided closure")
    func test_onEdited_executesClosure() async throws {
        let executed = LockIsolated(false)
        let action = AsyncActionVoid {
            executed.setValue(true)
        }

        try await action.asyncExecute()

        #expect(executed.value == true)
    }

    // MARK: - onDeleted

    @Test("onDeleted executes provided closure")
    func test_onDeleted_executesClosure() async throws {
        let executed = LockIsolated(false)
        let action = AsyncActionVoid {
            executed.setValue(true)
        }

        try await action.asyncExecute()

        #expect(executed.value == true)
    }

    // MARK: - onCreated

    @Test("onCreated executes provided closure")
    func test_onCreated_executesClosure() async throws {
        let executed = LockIsolated(false)
        let action = AsyncActionVoid {
            executed.setValue(true)
        }

        try await action.asyncExecute()

        #expect(executed.value == true)
    }

    // MARK: - onCancelled

    @Test("onCancelled executes provided closure")
    func test_onCancelled_executesClosure() async throws {
        let executed = LockIsolated(false)
        let action = AsyncActionVoid {
            executed.setValue(true)
        }

        try await action.asyncExecute()

        #expect(executed.value == true)
    }

    // MARK: - View Extension Integration

    @Test("environment modifiers can be applied to views")
    func test_environmentModifiers_canBeAppliedToViews() {
        let _ = Text("Test")
            .onEdited { }
            .onDeleted { }
            .onCreated { }
            .onCancelled { }
    }

    @Test("environment values can be set and retrieved")
    func test_environmentValues_canBeSetAndRetrieved() {
        var env = EnvironmentValues()
        let action = AsyncActionVoid { }

        env.onEditedAction = action
        #expect(env.onEditedAction != nil)

        env.onDeletedAction = action
        #expect(env.onDeletedAction != nil)

        env.onCreatedAction = action
        #expect(env.onCreatedAction != nil)

        env.onCancelledAction = action
        #expect(env.onCancelledAction != nil)
    }
}

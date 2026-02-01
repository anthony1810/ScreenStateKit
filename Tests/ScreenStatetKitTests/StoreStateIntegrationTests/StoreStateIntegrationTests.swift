//
//  StoreStateIntegrationTests.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//
import Testing
import ConcurrencyExtras
import ScreenStateKit

class StoreStateIntegrationTests {
    // MARK: - Action → State Flow

    @Test("receive action updates state via keypath")
    @MainActor
    func test_receiveAction_updatesStateViaKeyPath() async throws {
        let state = TestScreenState()
        let sut = TestStore()
        await sut.binding(state: state)

        await sut.isolatedReceive(action: .fetchUser(id: 123))

        #expect(state.userName == "User 123")
        #expect(state.isLoading == false)
    }

    // MARK: - Loading State Tests

    @Test("loading state tracks action execution")
    @MainActor
    func test_loadingState_tracksActionExecution() async throws {
        await withMainSerialExecutor {
            let state = TestScreenState()
            let sut = TestStore()
            await sut.binding(state: state)

            let task = Task { await sut.isolatedReceive(action: .slowFetch) }
            await Task.yield()

            #expect(state.isLoading == true)

            await task.value

            #expect(state.isLoading == false)
        }
    }

    @Test("action locker prevents duplicate action execution")
    @MainActor
    func test_actionLocker_preventsDuplicateExecution() async throws {
        await withMainSerialExecutor {
            let state = TestScreenState()
            let sut = TestStore()
            await sut.binding(state: state)
            
            sut.receive(action: .fetchUser(id: 1))
            sut.receive(action: .fetchUser(id: 2))
            
            await Task.megaYield()
            
            #expect(state.userName == "User 1")
            #expect(await sut.fetchCount == 1)
        }
    }

}

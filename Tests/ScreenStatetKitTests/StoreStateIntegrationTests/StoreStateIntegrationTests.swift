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

    // MARK: - Error Handling Tests

    @Test("error action sets displayError on state")
    @MainActor
    func test_errorAction_setsDisplayError() async throws {
        let state = TestScreenState()
        let sut = TestStore()
        await sut.binding(state: state)

        await sut.isolatedReceive(action: .failingAction)

        #expect(state.displayError?.errorDescription == "Something went wrong")
        #expect(state.isLoading == false)
    }

    // MARK: - LoadmoreScreenStates Integration Tests

    @Test("loadmore view triggers canExecuteLoadmore on disappear simulation")
    @MainActor
    func test_loadmoreView_triggersCanExecuteLoadmore() async throws {
        let state = TestLoadmoreState()
        let viewModel = TestLoadmoreStore()
        await viewModel.binding(state: state)

        state.simulateLoadmoreViewDisappear()

        #expect(state.canShowLoadmore == true)

        await viewModel.isolatedReceive(action: .loadMore)

        #expect(state.items.count == 10)
        #expect(state.canShowLoadmore == false)
    }

    // MARK: - Multi-Property StateUpdater Tests

    @Test("fetch user profile updates multiple properties atomically")
    @MainActor
    func test_fetchUserProfile_updatesMultipleProperties() async throws {
        let state = TestScreenState()
        let sut = TestStore()
        await sut.binding(state: state)

        await sut.isolatedReceive(action: .fetchUserProfile(id: 42))

        #expect(state.userName == "John Doe")
        #expect(state.userAge == 25)
        #expect(state.userEmail == "john@example.com")
        #expect(state.isLoading == false)
    }

    @Test("loadmore with pagination updates items, page, and hasMore atomically")
    @MainActor
    func test_loadMoreWithPagination_updatesMultipleProperties() async throws {
        let state = TestLoadmoreState()
        let viewModel = TestLoadmoreStore()
        await viewModel.binding(state: state)

        await viewModel.isolatedReceive(action: .loadMoreWithPagination(page: 2))

        #expect(state.items == Array(11...20))
        #expect(state.currentPage == 2)
        #expect(state.hasMorePages == true)
    }

}

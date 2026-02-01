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
    private var leakTrackers: [MemoryLeakTracker] = []

    deinit {
        leakTrackers.forEach { $0.verify() }
    }

    // MARK: - Action → State Flow

    @Test("receive action updates state via keypath")
    @MainActor
    func test_receiveAction_updatesStateViaKeyPath() async throws {
        let (state, sut) = await makeSUT()

        await sut.isolatedReceive(action: .fetchUser(id: 123))

        #expect(state.userName == "User 123")
        #expect(state.isLoading == false)
    }

    // MARK: - Loading State Tests

    @Test("loading state tracks action execution")
    @MainActor
    func test_loadingState_tracksActionExecution() async throws {
        await withMainSerialExecutor {
            let (state, sut) = await makeSUT()

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
            let (state, sut) = await makeSUT()

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
        let (state, sut) = await makeSUT()

        await sut.isolatedReceive(action: .failingAction)

        #expect(state.displayError?.errorDescription == "Something went wrong")
        #expect(state.isLoading == false)
    }

    // MARK: - LoadmoreScreenStates Integration Tests

    @Test("loadmore view triggers canExecuteLoadmore on disappear simulation")
    @MainActor
    func test_loadmoreView_triggersCanExecuteLoadmore() async throws {
        let (state, sut) = await makeLoadmoreSUT()

        state.simulateLoadmoreViewDisappear()

        #expect(state.canShowLoadmore == true)

        await sut.isolatedReceive(action: .loadMore)

        #expect(state.items.count == 10)
        #expect(state.canShowLoadmore == false)
    }

    // MARK: - Multi-Property StateUpdater Tests

    @Test("fetch user profile updates multiple properties atomically")
    @MainActor
    func test_fetchUserProfile_updatesMultipleProperties() async throws {
        let (state, sut) = await makeSUT()

        await sut.isolatedReceive(action: .fetchUserProfile(id: 42))

        #expect(state.userName == "John Doe")
        #expect(state.userAge == 25)
        #expect(state.userEmail == "john@example.com")
        #expect(state.isLoading == false)
    }

    @Test("loadmore with pagination updates items, page, and hasMore atomically")
    @MainActor
    func test_loadMoreWithPagination_updatesMultipleProperties() async throws {
        let (state, sut) = await makeLoadmoreSUT()

        await sut.isolatedReceive(action: .loadMoreWithPagination(page: 2))

        #expect(state.items == Array(11...20))
        #expect(state.currentPage == 2)
        #expect(state.hasMorePages == true)
    }
}

// MARK: - Helpers

extension StoreStateIntegrationTests {
    @MainActor
    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> (state: TestScreenState, store: TestStore) {
        let state = TestScreenState()
        let store = TestStore()
        await store.binding(state: state)
        trackForMemoryLeaks(state, sourceLocation: sourceLocation)
        trackForMemoryLeaks(store, sourceLocation: sourceLocation)
        return (state, store)
    }

    @MainActor
    private func makeLoadmoreSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> (state: TestLoadmoreState, store: TestLoadmoreStore) {
        let state = TestLoadmoreState()
        let store = TestLoadmoreStore()
        await store.binding(state: state)
        trackForMemoryLeaks(state, sourceLocation: sourceLocation)
        trackForMemoryLeaks(store, sourceLocation: sourceLocation)
        return (state, store)
    }

    private func trackForMemoryLeaks(
        _ instance: AnyObject,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        leakTrackers.append(MemoryLeakTracker(instance: instance, sourceLocation: sourceLocation))
    }
}

// MARK: - MemoryLeakTracker

extension StoreStateIntegrationTests {
    struct MemoryLeakTracker {
        weak var instance: AnyObject?
        var sourceLocation: SourceLocation

        func verify() {
            #expect(
                instance == nil,
                "Expected \(String(describing: instance)) to be deallocated. Potential memory leak",
                sourceLocation: sourceLocation
            )
        }
    }
}

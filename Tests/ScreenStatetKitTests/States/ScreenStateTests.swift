//
//  ScreenStateTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("ScreenState Tests")
@MainActor
struct ScreenStateTests {

    // MARK: - init() Tests

    @Test("init starts with no loading")
    func test_init_startsWithNoLoading() {
        let sut = makeSUT()

        #expect(sut.isLoading == false)
    }

    // MARK: - loadingStarted() Tests

    @Test("loadingStarted sets isLoading to true")
    func test_loadingStarted_setsIsLoadingToTrue() {
        let sut = makeSUT()

        sut.loadingStarted()

        #expect(sut.isLoading == true)
    }

    // MARK: - loadingFinished() Tests

    @Test("loadingFinished sets isLoading to false when counter reaches zero")
    func test_loadingFinished_setsIsLoadingToFalse() {
        let sut = makeSUT()

        sut.loadingStarted()
        sut.loadingFinished()

        #expect(sut.isLoading == false)
    }

    @Test("loadingFinished does not decrement below zero")
    func test_loadingFinished_doesNotDecrementBelowZero() {
        let sut = makeSUT()

        sut.loadingFinished()
        sut.loadingFinished()

        #expect(sut.isLoading == false)
    }

    @Test("isLoading stays true when counter above zero")
    func test_isLoading_staysTrueWhenCounterAboveZero() {
        let sut = makeSUT()

        sut.loadingStarted()
        sut.loadingStarted()
        sut.loadingFinished()

        #expect(sut.isLoading == true)
    }

    // MARK: - loadingStarted(action:) Tests

    @Test("loadingStarted with action only increments when canTrackLoading is true")
    func test_loadingStartedWithAction_onlyIncrementsWhenCanTrackLoading() {
        let sut = makeSUT()

        sut.loadingStarted(action: TestAction.trackable)
        #expect(sut.isLoading == true)

        sut.loadingFinished()

        sut.loadingStarted(action: TestAction.nonTrackable)
        #expect(sut.isLoading == false)
    }

    // MARK: - loadingFinished(action:) Tests

    @Test("loadingFinished with action only decrements when canTrackLoading is true")
    func test_loadingFinishedWithAction_onlyDecrementsWhenCanTrackLoading() {
        let sut = makeSUT()

        sut.loadingStarted()
        sut.loadingFinished(action: TestAction.nonTrackable)
        #expect(sut.isLoading == true)

        sut.loadingFinished(action: TestAction.trackable)
        #expect(sut.isLoading == false)
    }
    
    // MARK: - displayError Tests

    @Test("displayError resets isLoading to false")
    func test_displayError_resetsLoadingState() {
        let sut = makeSUT()
        sut.loadingStarted()
        #expect(sut.isLoading == true)

        sut.displayError = DisplayableError(message: "Error")

        #expect(sut.isLoading == false)
    }
    
    // MARK: - Parent Binding Tests

    @Test("parent binding propagates loading to parent when .loading option set")
    func test_parentBinding_propagatesLoadingToParent() {
        let parent = ScreenState()
        let child = ScreenState(states: parent, options: .loading)

        child.loadingStarted()
        #expect(parent.isLoading == true)

        child.loadingFinished()
        #expect(parent.isLoading == false)
    }

    @Test("parent binding propagates error to parent when .error option set")
    func test_parentBinding_propagatesErrorToParent() {
        let parent = ScreenState()
        let child = ScreenState(states: parent, options: .error)

        child.displayError = DisplayableError(message: "Child error")

        #expect(parent.displayError?.message == "Child error")
    }
    
    @Test("parent binding respects options - loading only does not propagate error")
    func test_parentBinding_respectsOptions() {
        let parent = ScreenState()
        let child = ScreenState(states: parent, options: .loading)

        child.displayError = DisplayableError(message: "Child error")

        #expect(parent.displayError == nil)
    }

}

// MARK: - Helpers

extension ScreenStateTests {
    private func makeSUT() -> ScreenState {
        ScreenState()
    }

    private enum TestAction: LoadingTrackable {
        case trackable
        case nonTrackable

        var canTrackLoading: Bool {
            switch self {
            case .trackable: return true
            case .nonTrackable: return false
            }
        }
    }
}

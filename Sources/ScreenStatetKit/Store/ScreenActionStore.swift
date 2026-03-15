//
//  ScreenActionStore.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation


public protocol ScreenActionStore: TypeNamed, Actor {
    
    associatedtype ViewState: ScreenState
    associatedtype Action: Sendable & Hashable
    
    /// Reference to the view state. Conforming types should store this as `weak`.
    var viewState: ViewState? { get }
    
    /// Handles an incoming action and performs the corresponding logic.
    /// - Parameter action: The action to process.
    /// - Throws: An error if the action handling fails.
    func receive(action: Action) async throws
}

extension ScreenActionStore {
    
    public var viewState: ScreenState? { .none }
    
    /// Dispatches an action from a non-isolated context.
    ///
    /// This method allows sending an `Action` to the actor without requiring
    /// the caller to `await`. Internally it creates a `Task` that forwards the
    /// action to `receive(action:)`.
    ///
    /// If a `CancelBag` is provided, the created task will be stored in the bag
    /// using the `action` as its identifier. This allows the task to be cancelled
    /// later or automatically replaced if another task with the same identifier
    /// is stored.
    ///
    /// - Parameters:
    ///   - action: The action to send to the receiver.
    ///   - bag: Optional `CancelBag` used to manage the lifetime of the created task.
    ///
    /// - Returns: The stored `AnyTask`.
    ///
    /// - Tip: If the ``CancelBag`` is tied to the lifetime of a view, its tasks
    ///   will be cancelled automatically when the view is destroyed.
    ///
    /// - Note: `Action` must conform to `Hashable` so it can be used as an
    ///   identifier for task cancellation.
    @discardableResult nonisolated
    public func nonisolatedReceive(
        action: Action,
        canceller: CancelBag? = .none
    ) -> AnyTask
    where Action: Hashable, Action: LoadingTrackable {
        if #available(iOS 26.0, macOS 26.0, *) {
            Task.immediate {
                await dispatch(action: action)
            }
            .store(in: canceller, withIdentifier: action)
        } else {
            Task {
                await dispatch(action: action)
            }
            .store(in: canceller, withIdentifier: action)
        }
    }

    private func dispatch(action: Action) async
    where Action: Hashable, Action: LoadingTrackable {
        await viewState?.loadingStarted(action: action)
        do {
            try await receive(action: action)
        } catch let displayable as DisplayableError where !displayable.isSilent {
            await viewState?.showError(displayable)
        } catch {
            printDebug(error.localizedDescription)
        }
        await viewState?.loadingFinished(action: action)
    }
    
    func printDebug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}

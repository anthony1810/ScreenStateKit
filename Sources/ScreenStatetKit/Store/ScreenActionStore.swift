//
//  ScreenActionStore.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation


public protocol ScreenActionStore: TypeNamed, Actor {
    
    associatedtype Action: Sendable & ActionLockable
    
    /// Handles the given action and performs the corresponding logic.
    ///
    /// - Parameter action: The action to process.
    func receive(action: Action) async
}

extension ScreenActionStore {
    
    /// `ActionStore` receive an action from a nonisolated context.
    ///
    /// This method allows dispatching an `Action` to the actor without requiring
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
    ///   - canceller: An optional `CancelBag` used to manage the lifetime of the
    ///     created task. If provided, the task will be stored using `action`
    ///     as its identifier.
    ///
    /// - Tip: If the ``CancelBag`` is tied to the lifetime of a view, its tasks will be
    ///   cancelled automatically when the view is destroyed. Otherwise, the tasks
    ///   are guaranteed to complete before the action store is deallocated.
    ///
    /// - Note: The `Action` type must conform to `Hashable` so it can be used
    ///   as a unique identifier for task cancellation.
    nonisolated
    public func nonisolatedReceive(
        action: Action,
        canceller: CancelBag? = .none
    )
    where Action: Hashable {
        Task {
            await receive(action: action)
        }.store(in: canceller, withIdentifier: action)
    }
}

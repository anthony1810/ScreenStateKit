//
//  ScreenActionStore.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation

public protocol ScreenActionStore: TypeNamed, Actor {

    associatedtype AScreenState: ScreenState
    associatedtype Action: Sendable & ActionLockable

    func binding(state: AScreenState)

    /// Async dispatch — suspends until the action completes. Cancellable via structured concurrency.
    /// Use this in `.task`, `.refreshable`, and any other async context where cancellation matters.
    func send(action: Action) async

    /// Fire-and-forget dispatch for sync contexts (button callbacks, `onAppear`, etc.)
    /// where you cannot `await`. The spawned task is not cancellable by the caller.
    nonisolated func receive(action: Action)
}

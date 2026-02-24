//
//  ActionLocker.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation

public struct ActionLocker {

    /// Use this when the locker is confined to a single actor or execution context.
    /// - Warning: Not thread-safe. For concurrent use, prefer ``ActionLocker/isolated``.
    public static var nonIsolated: NonIsolatedActionLocker { .init() }

    /// Use this when the locker is shared across multiple actors or concurrent contexts.
    /// This variant provides the necessary isolation to ensure thread safety.
    public static var isolated: IsolatedActionLocker { .init() }
}

// MARK: - Isolated
public actor IsolatedActionLocker {

    let locker: NonIsolatedActionLocker

    internal init() {
        locker = .init()
    }

    public func lock(_ action: ActionLockable) throws {
        try locker.lock(action)
    }

    public func unlock(_ action: ActionLockable) {
        locker.unlock(action)
    }

    public func canExecute(_ action: ActionLockable) -> Bool {
        locker.canExecute(action)
    }

    public func free() {
        locker.free()
    }
}

// MARK: - Nonisolated
/// A non-thread-safe action locker for use within a single concurrency context.
///
/// - Important: This type has no synchronisation. It must only be accessed
///   from a single actor or serial queue. For use across multiple concurrent
///   contexts, use ``IsolatedActionLocker`` instead.
public final class NonIsolatedActionLocker {

    private var actions: [AnyHashable: Bool]

    internal init() {
        actions = .init()
    }

    public func lock(_ action: ActionLockable) throws {
        let isRunning = actions[action.lockKey] ?? false
        guard !isRunning else {
            throw ActionLocker.Errors.actionIsRunning
        }
        actions.updateValue(true, forKey: action.lockKey)
    }

    public func unlock(_ action: ActionLockable) {
        guard actions[action.lockKey] != .none else { return }
        actions.updateValue(false, forKey: action.lockKey)
    }

    public func canExecute(_ action: ActionLockable) -> Bool {
        do {
            try lock(action)
            return true
        } catch {
            return false
        }
    }

    public func free() {
        actions.removeAll()
    }
}

extension ActionLocker {

    public enum Errors: Error {
        case actionIsRunning
    }
}

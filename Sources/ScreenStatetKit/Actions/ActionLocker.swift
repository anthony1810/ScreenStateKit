//
//  ActionLocker.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import Foundation

public actor ActionLocker {
    
    private var actions: [AnyHashable: Bool]
    
    public init() {
        actions = .init()
    }
    
    public func lock(_ action: ActionLockable) throws {
        let isRunning = actions[action.lockKey] ?? false
        guard !isRunning else {
            throw Errors.actionIsRunning
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


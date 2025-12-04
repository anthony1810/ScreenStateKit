//
//  ActionLocker.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import Foundation

public actor ActionLocker {
    
    private var actions: [String: Bool]
    
    public init() {
        actions = .init()
    }
    
    public func lock(_ action: ActionLockable) throws {
        let isRunning = actions[action.lockkey] ?? false
        guard !isRunning else {
            throw Errors.actionIsRunning
        }
        actions.updateValue(true, forKey: action.lockkey)
    }
    
    public func unlock(_ action: ActionLockable) {
        guard actions[action.lockkey] != .none else { return }
        actions.updateValue(false, forKey: action.lockkey)
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


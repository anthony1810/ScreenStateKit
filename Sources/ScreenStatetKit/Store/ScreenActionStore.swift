//
//  ScreenActionStore.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation

@available(macOS 10.15, *)
public protocol ScreenActionStore: ObservableObject, TypeNamed, Actor {
    
    associatedtype ScreenState: ScreenStates
    associatedtype Action: Sendable & ActionLockable
    
    func binding(state: ScreenState)
    
    nonisolated func receive(action: Action)
}

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
    
    nonisolated func receive(action: Action)
}

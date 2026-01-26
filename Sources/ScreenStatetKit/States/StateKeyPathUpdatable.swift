//
//  StateKeyPathUpdatable.swift
//  ScreenStateKit
//
//  Created by Thang Kieu on 26/1/26.
//

import SwiftUI

@MainActor
public protocol StateKeyPathUpdatable: AnyObject {
    
    func updateState<each T>(_ updater: repeat StateUpdater<Self, each T>,
                             withAnimation animation: Animation?)
}

extension StateKeyPathUpdatable {
    
    private func updateState<T>(keyPath: ReferenceWritableKeyPath<Self,T>,
                                newValue: T) {
        self[keyPath: keyPath] = newValue
    }
    
    public func updateState<each T>(_ updater: repeat StateUpdater<Self, each T>,
                                    withAnimation animation: Animation? = .none) {
        var transaction: Transaction = .init()
        transaction.animation = animation
        withTransaction(transaction) {
            repeat updateState(keyPath: (each updater).keypath(), newValue: (each updater).value)
        }
    }
}

public struct StateUpdater<Root, Value>: Sendable where Value: Sendable {
    
    public typealias KeyPathGetter = @MainActor @Sendable () -> ReferenceWritableKeyPath<Root, Value>
    
    public let keypath: KeyPathGetter
    public let value: Value
    
    public init(keypath: @escaping @autoclosure KeyPathGetter,
                value: Value) {
        self.keypath = keypath
        self.value = value
    }
}

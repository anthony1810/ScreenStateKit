//
//  StateUpdatable.swift
//  ScreenStateKit
//
//  Created by Thang Kieu on 26/1/26.
//

import SwiftUI

@MainActor
public protocol StateUpdatable: Sendable {
    
    func updateState(withAnimation animation: Animation?,
                     _ updateBlock: @MainActor @Sendable (_ state: Self) -> Void)
}


extension StateUpdatable {

    public func updateState(withAnimation animation: Animation? = .smooth,
                            _ updateBlock: @MainActor @Sendable (_ state: Self) -> Void) {
        var transaction = Transaction()
        transaction.animation = animation
        transaction.disablesAnimations = animation == .none
        withTransaction(transaction) {
            updateBlock(self)
        }
    }

    /// Reads several `@MainActor` values in a single hop and returns them as a tuple.
    ///
    ///     let values: (queue: [Item], isShowing: Bool) = await state.readState { state in
    ///         state.queue
    ///         state.isShowing
    ///     }
    public func readState<T: Sendable>(@StateValueBuilder _ readBlock: @MainActor @Sendable (_ state: Self) -> T) -> T {
        readBlock(self)
    }
}


@resultBuilder
public enum StateValueBuilder {

    /// One value returns that value; multiple values return a tuple of matching arity.
    public static func buildBlock<each Value>(_ value: repeat each Value) -> (repeat each Value) {
        (repeat each value)
    }
}

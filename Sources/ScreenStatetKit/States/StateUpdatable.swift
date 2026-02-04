//
//  StateUpdatable.swift
//  ScreenStateKit
//
//  Created by Thang Kieu on 26/1/26.
//

import SwiftUI

@MainActor
public protocol StateUpdatable {
    
    func updateState(withAnimation animation: Animation?,
                     _ updateBlock: @MainActor (_ state: Self) -> Void)
}


extension StateUpdatable {
    
    public func updateState(withAnimation animation: Animation? = .smooth,
                            _ updateBlock: @MainActor (_ state: Self) -> Void) {
        var transaction = Transaction()
        transaction.animation = animation
        transaction.disablesAnimations = animation == .none
        withTransaction(transaction) {
            updateBlock(self)
        }
    }
}

//
//  StateUpdatable.swift
//  ScreenStateKit
//
//  Created by Thang Kieu on 26/1/26.
//

import SwiftUI

@MainActor
public protocol StateUpdatable {
    
    func updateState( _ updateBlock: @MainActor (_ state: Self) -> Void,
                      withAnimation animation: Animation?,
                      disablesAnimations: Bool)
}


extension StateUpdatable {
    
    public func updateState( _ updateBlock: @MainActor (_ state: Self) -> Void,
                             withAnimation animation: Animation? = .none,
                             disablesAnimations: Bool = false) {
        var transaction = Transaction()
        transaction.animation = animation
        transaction.disablesAnimations = disablesAnimations
        withTransaction(transaction) {
            updateBlock(self)
        }
    }
}

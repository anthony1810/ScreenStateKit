//
//  ActionLockable.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

public protocol ActionLockable {
    var lockKey: AnyHashable { get }
}

extension ActionLockable where Self: Hashable {
    public var lockKey: AnyHashable {
        self
    }
}

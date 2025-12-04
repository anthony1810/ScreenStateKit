//
//  ActionLockable.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

public protocol ActionLockable {
    var lockkey: String { get }
}

extension ActionLockable {
    public var lockkey: String {
        let name = String(describing: self).prefix(100)
        return String(name)
    }
}

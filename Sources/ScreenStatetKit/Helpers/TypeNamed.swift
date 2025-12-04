//
//  TypeNamed.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import Foundation

public protocol TypeNamed {
    var declaredName: String { get }
}

extension TypeNamed {
    
    public static var typeNamed: String {
        String(describing: Self.self)
    }
    
    public var declaredName: String {
        String(describing: type(of: self))
    }
}


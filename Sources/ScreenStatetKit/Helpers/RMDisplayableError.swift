//
//  RMDisplayableError.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import SwiftUI

public struct RMDisplayableError: LocalizedError, Identifiable, Hashable {
    
    public let id: String
    public var errorDescription: String? {
        message
    }
    let message: String
    
    init(message: String) {
        self.message = message
        self.id = UUID().uuidString
    }
}


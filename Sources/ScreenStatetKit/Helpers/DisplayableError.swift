//
//  DisplayableError.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import SwiftUI

public protocol NonPresentableError: Error {
    var isSilent: Bool { get }
}

extension NonPresentableError {
    public var isSilent: Bool { true }
}

public struct DisplayableError: LocalizedError, Identifiable, Hashable {

    public let id: UUID
    public var errorDescription: String? {
        message
    }
    public let message: String
    public let originalError: Error?
    let isSilent: Bool
    
    public init(message: String, error: Error? = .none) {
        self.message = message
        self.id = UUID()
        self.isSilent = (error as? NonPresentableError)?.isSilent == true
        if let displayable = error as? DisplayableError {
            self.originalError = displayable.originalError
        } else {
            self.originalError = error
        }
    }
    
    public init(error: Error) {
        self.message = error.localizedDescription
        self.id = UUID()
        self.isSilent = (error as? NonPresentableError)?.isSilent == true
        if let displayable = error as? DisplayableError {
            self.originalError = displayable.originalError
        } else {
            self.originalError = error
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DisplayableError, rhs: DisplayableError) -> Bool {
        lhs.id == rhs.id
    }
}



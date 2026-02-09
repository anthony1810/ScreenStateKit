//
//  DisplayableError.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import SwiftUI

public struct DisplayableError: LocalizedError, Identifiable, Hashable {

    public let id: String
    public var errorDescription: String? {
        message
    }
    let message: String

    public init(message: String) {
        self.message = message
        self.id = UUID().uuidString
    }
}


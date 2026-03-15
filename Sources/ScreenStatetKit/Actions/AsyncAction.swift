//
//  AsyncAction.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import Foundation

public typealias AsyncActionVoid = AsyncAction<Void,Void>
public typealias AsyncActionGet<Output> = AsyncAction<Void,Output>
public typealias AsyncActionPut<Input> = AsyncAction<Input,Void>

public struct AsyncAction<Input,Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    public typealias WorkAction = @Sendable @isolated(any) (Input) async throws -> Output
    public let name: String?
    
    private let identifier = UUID()
    private let action: WorkAction
    
    public init (name: String? = .none,
                 _ action: @escaping WorkAction) {
        self.name = name
        self.action = action
    }
    
    @discardableResult
    public func asyncExecute(isolation: isolated (any Actor)? = #isolation,
                             _ input: Input) async throws -> Output {
        try await action(input)
    }
}

extension AsyncAction where Input == Void {
    
    @discardableResult
    public func asyncExecute(isolation: isolated (any Actor)? = #isolation) async throws -> Output {
        try await action(Void())
    }
}


extension AsyncAction where Output == Void {
    
    public func execute(_ input: Input) {
        if #available(iOS 26.0, *) {
            Task.immediate {
                try await action(input)
            }
        } else {
            Task {
                try await action(input)
            }
        }
    }
}


extension AsyncAction where Output == Void, Input == Void {
    
    public func execute() {
        if #available(iOS 26.0, *) {
            Task.immediate {
                try await action(Void())
            }
        } else {
            Task {
                try await action(Void())
            }
        }
    }
}

extension AsyncAction: Hashable {
    
    public static func == (lhs: AsyncAction<Input, Output>, rhs: AsyncAction<Input, Output>) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

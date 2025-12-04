//
//  Environment+Extensions.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//


import SwiftUI

//MARK: - Actions

@available(macOS 10.15, *)
extension View {
    public func onEdited(_ action: @escaping @Sendable @MainActor () async -> Void) -> some View {
        environment(\.onEditedAction, .init(action))
    }
    
    public func onDeleted(_ action: @escaping @Sendable @MainActor () async -> Void) -> some View {
        environment(\.onDeletedAction, .init(action))
    }
    
    public func onCreated(_ action: @escaping @Sendable @MainActor () async -> Void) -> some View {
        environment(\.onCreatedAction, .init(action))
    }
}

@available(macOS 10.15, *)
extension EnvironmentValues {
    @Entry public var onEditedAction: AsyncActionVoid? = nil
    @Entry public var onDeletedAction: AsyncActionVoid? = nil
    @Entry public var onCreatedAction: AsyncActionVoid? = nil
}

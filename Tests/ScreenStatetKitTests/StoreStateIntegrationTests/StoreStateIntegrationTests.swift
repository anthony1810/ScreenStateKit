//
//  StoreStateIntegrationTests.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//
import Testing

import ScreenStateKit

class StoreStateIntegrationTests {
    // MARK: - Action → State Flow
    
    @Test("receive action updates state via keypath")
    @MainActor
    func test_receiveAction_updatesStateViaKeyPath() async throws {
        let state = TestScreenState()
        let sut = TestStore()
        await sut.binding(state: state)
        
        await sut.isolatedReceive(action: .fetchUser(id: 123))
        
        #expect(state.userName == "User 123")
        #expect(state.isLoading == false)
    }
}

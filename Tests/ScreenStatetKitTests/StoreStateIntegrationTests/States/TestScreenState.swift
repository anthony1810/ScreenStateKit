//
//  TestScreenState.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//
import ScreenStateKit

extension StoreStateIntegrationTests {
    @MainActor
    final class TestScreenState: ScreenState, StateUpdatable {
        var userName: String = ""
        var userAge: Int = 0
        var userEmail: String = ""
    }
}

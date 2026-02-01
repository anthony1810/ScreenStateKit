//
//  TestLoadmoreState.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//

import ScreenStateKit

extension StoreStateIntegrationTests {
    @MainActor
    final class TestLoadmoreState: LoadmoreScreenStates, StateKeyPathUpdatable {
        var items: [Int] = []
        
        func simulateLoadmoreViewDisappear() {
            canExecuteLoadmore()
        }
    }
}

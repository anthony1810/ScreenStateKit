//
//  TestLoadmoreState.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//

import ScreenStateKit

extension StoreStateIntegrationTests {
    @MainActor
    final class TestLoadmoreState: LoadmoreScreenState, StateUpdatable {
        var items: [Int] = []
        var currentPage: Int = 1
        var hasMorePages: Bool = false

        func simulateLoadmoreViewDisappear() {
            canExecuteLoadmore()
        }
    }
}

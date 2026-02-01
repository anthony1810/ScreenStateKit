//
//  TestLoadMoreStore.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//

import Foundation
import ScreenStateKit

extension StoreStateIntegrationTests {
    actor TestLoadmoreStore: ScreenActionStore {
        private var state: TestLoadmoreState?
        private let actionLocker = ActionLocker()
        
        func binding(state: TestLoadmoreState) {
            self.state = state
        }
        
        nonisolated func receive(action: Action) {
            Task { await isolatedReceive(action: action) }
        }
        
        private func isolatedReceive(action: Action) async {
            guard await actionLocker.canExecute(action) else { return }
            await state?.loadingStarted(action: action)
            
            switch action {
            case .loadMore:
                await state?.updateState(StateUpdater(keypath: \.items, value: Array(1...10)))
                await state?.ternimateLoadmoreView()
            }
            
            await actionLocker.unlock(action)
            await state?.loadingFinished(action: action)
        }
        
        enum Action: ActionLockable, LoadingTrackable {
            case loadMore
            
            var canTrackLoading: Bool { true }
        }
    }
}

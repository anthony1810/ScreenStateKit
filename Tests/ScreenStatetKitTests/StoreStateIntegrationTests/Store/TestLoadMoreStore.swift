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
        private let actionLocker = ActionLocker.nonIsolated

        func binding(state: TestLoadmoreState) {
            self.state = state
        }

        nonisolated func receive(action: Action) {
            Task { await isolatedReceive(action: action) }
        }

        func isolatedReceive(action: Action) async {
            guard actionLocker.canExecute(action) else { return }
            await state?.loadingStarted(action: action)

            switch action {
            case .loadMore:
                await state?.updateState { state in
                    state.items = Array(1...10)
                }
                await state?.ternimateLoadmoreView()

            case .loadMoreWithPagination(let page):
                let items = makeItemsForPage(page)
                let hasMore = page < 5
                await state?.updateState { state in
                    state.items = items
                    state.currentPage = page
                    state.hasMorePages = hasMore
                }
                await state?.ternimateLoadmoreView()
            }

            actionLocker.unlock(action)
            await state?.loadingFinished(action: action)
        }

        /// Generates items for a given page (10 items per page)
        /// - Page 1: [1, 2, 3, ..., 10]
        /// - Page 2: [11, 12, 13, ..., 20]
        /// - Page 3: [21, 22, 23, ..., 30]
        private func makeItemsForPage(_ page: Int) -> [Int] {
            let start = (page - 1) * 10 + 1
            let end = page * 10
            return Array(start...end)
        }

        enum Action: ActionLockable, LoadingTrackable, Hashable {
            case loadMore
            case loadMoreWithPagination(page: Int)

            var canTrackLoading: Bool { true }
        }
    }
}

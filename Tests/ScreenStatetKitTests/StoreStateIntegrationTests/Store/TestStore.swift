//
//  TestStore.swift
//  ScreenStateKit
//
//  Created by Anthony on 1/2/26.
//
import Foundation
import ScreenStateKit

extension StoreStateIntegrationTests {
    
    actor TestStore: ScreenActionStore {
        private var state: TestScreenState?
        private let actionLocker = ActionLocker()
        private(set) var fetchCount = 0
        
        func binding(state: TestScreenState) {
            self.state = state
        }
        
        nonisolated func receive(action: Action) {
            Task {
                await isolatedReceive(action: action)
            }
        }
        
        func isolatedReceive(action: Action) async {
            guard await actionLocker.canExecute(action) else { return }
            await state?.loadingStarted(action: action)
            
            do {
                switch action {
                case .fetchUser(let id):
                    fetchCount += 1
                    await state?.updateState(StateUpdater(keypath: \.userName, value: "User \(id)"))
                    
                case .slowFetch:
                    try await Task.sleep(for: .milliseconds(100))
                    
                case .failingAction:
                    throw TestError.somethingWentWrong
                }
            } catch {
                await state?.showError(RMDisplayableError(message: error.localizedDescription))
            }
            
            await actionLocker.unlock(action)
            await state?.loadingFinished(action: action)
        }
        
        private func execute(action: Action) async throws {
            switch action {
            case .fetchUser(let id):
                fetchCount += 1
                await state?.updateState(StateUpdater(keypath: \.userName, value: "User \(id)"))
                
            case .slowFetch:
                try await Task.sleep(for: .milliseconds(100))
                
            case .failingAction:
                throw TestError.somethingWentWrong
            }
        }
        
        enum Action: ActionLockable, LoadingTrackable {
            case fetchUser(id: Int)
            case slowFetch
            case failingAction
            
            var canTrackLoading: Bool { true }
        }
        
        enum TestError: LocalizedError {
            case somethingWentWrong
            
            var errorDescription: String? { "Something went wrong" }
        }
    }
    
}

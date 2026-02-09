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
        private let actionLocker = ActionLocker.nonIsolated
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
            guard actionLocker.canExecute(action) else { return }
            await state?.loadingStarted(action: action)
            
            do {
                switch action {
                case .fetchUser(let id):
                    fetchCount += 1
                    await state?.updateState { state in
                        state.userName = "User \(id)"
                    }
                case .fetchUserProfile:
                    fetchCount += 1
                    await state?.updateState { state in
                        state.userName = "John Doe"
                        state.userAge = 25
                        state.userEmail = "john@example.com"
                    }
                case .slowFetch:
                    try await Task.sleep(for: .milliseconds(100))

                case .failingAction:
                    throw TestError.somethingWentWrong
                }
            } catch {
                await state?.showError(DisplayableError(message: error.localizedDescription))
            }
            
            actionLocker.unlock(action)
            await state?.loadingFinished(action: action)
        }
        
        enum Action: ActionLockable, LoadingTrackable {
            case fetchUser(id: Int)
            case fetchUserProfile(id: Int)
            case slowFetch
            case failingAction

            var canTrackLoading: Bool { true }

            var lockKey: AnyHashable {
                switch self {
                case .fetchUser:
                    return "fetchUser"
                case .fetchUserProfile:
                    return "fetchUserProfile"
                case .slowFetch:
                    return "slowFetch"
                case .failingAction:
                    return "failingAction"
                }
            }
        }
        
        enum TestError: LocalizedError {
            case somethingWentWrong
            
            var errorDescription: String? { "Something went wrong" }
        }
    }
    
}

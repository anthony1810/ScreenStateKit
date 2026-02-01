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

                case .fetchUserProfile:
                    fetchCount += 1
                    await state?.updateState(
                        StateUpdater(keypath: \.userName, value: "John Doe"),
                        StateUpdater(keypath: \.userAge, value: 25),
                        StateUpdater(keypath: \.userEmail, value: "john@example.com")
                    )

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
        
        enum Action: ActionLockable, LoadingTrackable {
            case fetchUser(id: Int)
            case fetchUserProfile(id: Int)
            case slowFetch
            case failingAction

            var canTrackLoading: Bool { true }

            var lockkey: String {
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

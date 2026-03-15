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
        private(set) var viewState: TestScreenState?
        private let actionLocker = ActionLocker.nonIsolated
        private(set) var fetchCount = 0
        
        func binding(state: TestScreenState) {
            self.viewState = state
        }
        
        func receive(action: Action) async throws {
            guard actionLocker.canExecute(action) else { return }
            defer { actionLocker.unlock(action) }
            do {
                switch action {
                case .fetchUser(let id):
                    fetchCount += 1
                    await viewState?.updateState { state in
                        state.userName = "User \(id)"
                    }
                case .fetchUserProfile:
                    fetchCount += 1
                    await viewState?.updateState { state in
                        state.userName = "John Doe"
                        state.userAge = 25
                        state.userEmail = "john@example.com"
                    }
                case .slowFetch:
                    try await Task.sleep(for: .milliseconds(100))

                case .failingAction:
                    throw TestError.somethingWentWrong
                case .faillingWithSilentError:
                    throw TestError.silentError
                }
            } catch {
                throw DisplayableError(error: error)
            }
        }
        
        enum Action: ActionLockable, LoadingTrackable, Hashable {
            case fetchUser(id: Int)
            case fetchUserProfile(id: Int)
            case slowFetch
            case failingAction
            case faillingWithSilentError

            var canTrackLoading: Bool { true }
        }
        
        enum TestError: LocalizedError, NonPresentableError {
            case somethingWentWrong
            case silentError
            var errorDescription: String? {
                switch self {
                case .somethingWentWrong:
                    "Something went wrong"
                case .silentError:
                    "The silent error"
                }
            }
            
            var isSilent: Bool {
                switch self {
                case .somethingWentWrong:
                    false
                case .silentError:
                    true
                }
            }
        }
    }
    
}

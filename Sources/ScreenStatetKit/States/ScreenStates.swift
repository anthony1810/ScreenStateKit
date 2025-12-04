import SwiftUI
import Combine

//MARK: - Base Screen States
@available(macOS 10.15, *)
@MainActor
open class ScreenStates: ObservableObject, Sendable {
    
    @Published
    public var isLoading: Bool = false {
        didSet {
            guard parentStateOption.contains(.loading) else { return }
            if isLoading {
                parentState?.loadingStarted()
            } else {
                parentState?.loadingFinished()
            }
        }
    }
    
    @Published
    public var displayError: RMDisplayableError? {
        didSet {
            if let displayError {
                isLoading = false
                if parentStateOption.contains(.error) {
                    parentState?.showError(displayError)
                }
            } else {
                updateStateLoading()
            }
        }
    }
    
    private weak var parentState: ScreenStates?
    private let parentStateOption: BindingParentStateOption
    
    private var loadingTaskCount: Int = 0 {
        didSet {
            updateStateLoading()
        }
    }
    
    public init() {
        parentStateOption = .all
    }

    public init(states: ScreenStates, options: BindingParentStateOption) {
        parentState = states
        self.parentStateOption = options
    }
    
    public init(states: ScreenStates) {
        parentState = states
        self.parentStateOption = .all
    }
}

//MARK: - Updaters
extension ScreenStates {
    
    public struct BindingParentStateOption: OptionSet {
        
        public let rawValue: Int
        public static let loading = BindingParentStateOption(rawValue: 1 << 0)
        public static let error = BindingParentStateOption(rawValue: 1 << 1)
        
        public static let all: BindingParentStateOption = [.loading, .error]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    private func updateStateLoading() {
        let loading = loadingTaskCount > 0
        if loading != self.isLoading {
            withAnimation {
                isLoading = loading
            }
        }
    }
    
    public func showError(_ error: LocalizedError) {
        withAnimation {
            self.displayError = .init(message: error.localizedDescription)
        }
    }
    
    public func loadingStarted() {
        loadingTaskCount += 1
    }
    
    public func loadingFinished() {
        guard loadingTaskCount > 0 else { return }
        loadingTaskCount -= 1
    }
    
    public func loadingStarted(action: LoadingTrackable) {
        guard action.canTrackLoading else { return }
        loadingStarted()
    }
    
    public func loadingFinished(action: LoadingTrackable) {
        guard action.canTrackLoading else { return }
        loadingFinished()
    }
}

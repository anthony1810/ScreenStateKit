import SwiftUI

@MainActor
@Observable
public final class AppRefresher {
    public private(set) var action: AppRefreshAction

    public init() {
        self.action = AppRefreshAction(option: .idle)
    }

    public func refresh(_ option: AppRefreshAction.RefreshOption) {
        action = AppRefreshAction(option: option)
    }
}

public extension AppRefresher {

    enum Behavior: Int8, Sendable {
        case immediate
        case onNextAppear
    }
}

public struct AppRefreshAction: Equatable, Sendable {

    public struct RefreshOption: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let idle = RefreshOption(rawValue: 1 << 0)
    }

    public let requestId: UUID
    public let option: RefreshOption

    public init(option: RefreshOption) {
        self.requestId = UUID()
        self.option = option
    }
}

public extension EnvironmentValues {
    @Entry var appRefresher: AppRefresher? = nil
}

public extension View {

    func appRefresherHost() -> some View {
        modifier(AppRefresherHostModifier())
    }

    func appRefresherHost(_ refresher: AppRefresher) -> some View {
        environment(\.appRefresher, refresher)
    }

    func onAppRefresh(
        _ option: AppRefreshAction.RefreshOption,
        behavior: AppRefresher.Behavior = .onNextAppear,
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(AppRefreshActionModifier(option: option, behavior: behavior, action: action))
    }
}

private struct AppRefresherHostModifier: ViewModifier {
    @State private var refresher = AppRefresher()

    func body(content: Content) -> some View {
        content.environment(\.appRefresher, refresher)
    }
}

private struct AppRefreshActionModifier: ViewModifier {

    @Environment(\.appRefresher) private var refresher
    @State private var pendingRefreshId: UUID?

    let option: AppRefreshAction.RefreshOption
    let behavior: AppRefresher.Behavior
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard pendingRefreshId != nil, behavior == .onNextAppear else { return }
                pendingRefreshId = nil
                action()
            }
            .onChange(of: refresher?.action) { _, newValue in
                guard let newValue, newValue.option.contains(option) else { return }
                switch behavior {
                case .immediate:
                    action()
                case .onNextAppear:
                    pendingRefreshId = newValue.requestId
                }
            }
    }
}

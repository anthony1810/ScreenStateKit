import SwiftUI

@MainActor
@Observable
public final class AppRefresher<Option: OptionSet & Sendable, Source: Sendable> {
    public private(set) var action: AppRefreshAction<Option, Source>?

    public init() {}

    public func refresh(_ option: Option, source: Source? = nil) {
        action = AppRefreshAction(option: option, source: source)
    }
}

public enum AppRefreshBehavior: Int8, Sendable {
    case immediate
    case onNextAppear
}

public struct AppRefreshAction<Option: Sendable, Source: Sendable>: Sendable, Identifiable {
    public let id: UUID
    public let option: Option
    public let source: Source?

    public init(option: Option, source: Source? = nil) {
        self.id = UUID()
        self.option = option
        self.source = source
    }
}

public extension View {

    func appRefresherHost<Option, Source>(
        option: Option.Type,
        source: Source.Type
    ) -> some View where Option: OptionSet & Sendable, Source: Sendable {
        modifier(AppRefresherHostModifier<Option, Source>())
    }

    func appRefresherHost<Option, Source>(_ refresher: AppRefresher<Option, Source>) -> some View
    where Option: OptionSet & Sendable, Source: Sendable {
        environment(refresher)
    }

    func onAppRefresh<Option, Source>(
        _ option: Option,
        behavior: AppRefreshBehavior = .onNextAppear,
        perform action: @escaping (Source?) -> Void
    ) -> some View where Option: OptionSet & Sendable, Source: Sendable {
        modifier(AppRefreshActionModifier<Option, Source>(option: option, behavior: behavior, action: action))
    }
}

private struct AppRefresherHostModifier<Option: OptionSet & Sendable, Source: Sendable>: ViewModifier {
    @State private var refresher = AppRefresher<Option, Source>()

    func body(content: Content) -> some View {
        content.environment(refresher)
    }
}

private struct AppRefreshActionModifier<Option: OptionSet & Sendable, Source: Sendable>: ViewModifier {

    @Environment(AppRefresher<Option, Source>.self) private var refresher: AppRefresher<Option, Source>?
    @State private var pending: AppRefreshAction<Option, Source>?

    let option: Option
    let behavior: AppRefreshBehavior
    let action: (Source?) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard behavior == .onNextAppear, let pending else { return }
                self.pending = nil
                action(pending.source)
            }
            .onChange(of: refresher?.action?.id) { _, newId in
                guard newId != nil, let current = refresher?.action else { return }
                guard current.option.isSuperset(of: option) else { return }
                switch behavior {
                case .immediate:
                    action(current.source)
                case .onNextAppear:
                    pending = current
                }
            }
    }
}

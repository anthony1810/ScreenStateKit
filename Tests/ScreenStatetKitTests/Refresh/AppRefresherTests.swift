//
//  AppRefresherTests.swift
//  ScreenStateKit
//

import Testing
import SwiftUI
@testable import ScreenStateKit

private extension AppRefreshAction.RefreshOption {
    static let inbox = AppRefreshAction.RefreshOption(rawValue: 1 << 1)
    static let channelState = AppRefreshAction.RefreshOption(rawValue: 1 << 2)
}

@Suite("AppRefresher Tests")
@MainActor
struct AppRefresherTests {

    @Test("init starts in idle")
    func test_init_startsIdle() {
        let sut = AppRefresher()

        #expect(sut.action.option == .idle)
    }

    @Test("refresh updates the current option")
    func test_refresh_updatesOption() {
        let sut = AppRefresher()

        sut.refresh(.inbox)

        #expect(sut.action.option == .inbox)
    }

    @Test("refreshing the same option twice produces a new requestId")
    func test_refresh_sameOptionTwice_producesUniqueRequestIds() {
        let sut = AppRefresher()

        sut.refresh(.inbox)
        let first = sut.action.requestId
        sut.refresh(.inbox)
        let second = sut.action.requestId

        #expect(first != second)
    }

    @Test("refresh can carry combined options")
    func test_refresh_combinedOptions() {
        let sut = AppRefresher()

        sut.refresh([.inbox, .channelState])

        #expect(sut.action.option.contains(.inbox))
        #expect(sut.action.option.contains(.channelState))
    }

    @Test("idle option does not contain consumer options")
    func test_idle_doesNotContainConsumerOptions() {
        let sut = AppRefresher()

        #expect(sut.action.option.contains(.inbox) == false)
    }

    @Test("environment value can be set and retrieved")
    func test_environmentValue_setAndRetrieve() {
        var env = EnvironmentValues()
        #expect(env.appRefresher == nil)

        env.appRefresher = AppRefresher()
        #expect(env.appRefresher != nil)
    }

    @Test("view modifiers can be applied to views")
    func test_viewModifiers_canBeApplied() {
        let _ = Text("Test")
            .appRefresherHost()
            .onAppRefresh(.inbox) { }

        let refresher = AppRefresher()
        let _ = Text("Test")
            .appRefresherHost(refresher)
            .onAppRefresh(.channelState, behavior: .immediate) { }
    }
}

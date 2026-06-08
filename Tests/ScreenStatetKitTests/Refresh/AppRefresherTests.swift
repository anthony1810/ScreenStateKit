//
//  AppRefresherTests.swift
//  ScreenStateKit
//

import Testing
import SwiftUI
@testable import ScreenStateKit

private struct TestOption: OptionSet, Sendable {
    let rawValue: Int
    static let inbox = TestOption(rawValue: 1 << 0)
    static let settings = TestOption(rawValue: 1 << 1)
}

private enum TestSource: Sendable, Equatable {
    case newSetting(String)
    case newSession(Int)
}

private typealias SUT = AppRefresher<TestOption, TestSource>

@Suite("AppRefresher Tests")
@MainActor
struct AppRefresherTests {

    @Test("init starts with no action")
    func test_init_noAction() {
        let sut = SUT()

        #expect(sut.action == nil)
    }

    @Test("refresh records the option and leaves source nil by default")
    func test_refresh_recordsOption_noSource() {
        let sut = SUT()

        sut.refresh(.inbox)

        #expect(sut.action?.option == .inbox)
        #expect(sut.action?.source == nil)
    }

    @Test("refresh carries the source payload object")
    func test_refresh_carriesSourcePayload() {
        let sut = SUT()

        sut.refresh(.settings, source: .newSetting("dark"))

        #expect(sut.action?.option == .settings)
        #expect(sut.action?.source == .newSetting("dark"))
    }

    @Test("refresh can combine options in one signal")
    func test_refresh_combinedOptions() {
        let sut = SUT()

        sut.refresh([.inbox, .settings], source: .newSession(7))

        #expect(sut.action?.option.contains(.inbox) == true)
        #expect(sut.action?.option.contains(.settings) == true)
        #expect(sut.action?.source == .newSession(7))
    }

    @Test("refreshing the same option twice produces a new id")
    func test_refresh_sameOptionTwice_producesUniqueIds() {
        let sut = SUT()

        sut.refresh(.inbox)
        let first = sut.action?.id
        sut.refresh(.inbox)
        let second = sut.action?.id

        #expect(first != nil)
        #expect(first != second)
    }

    @Test("view modifiers can be applied to views")
    func test_viewModifiers_canBeApplied() {
        let _ = Text("Test")
            .appRefresherHost(option: TestOption.self, source: TestSource.self)
            .onAppRefresh(TestOption.inbox) { (_: TestSource?) in }

        let refresher = SUT()
        let _ = Text("Test")
            .appRefresherHost(refresher)
            .onAppRefresh(TestOption.settings, behavior: .immediate) { (_: TestSource?) in }
    }
}

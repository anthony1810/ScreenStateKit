//
//  RMLoadmoreViewTests.swift
//  ScreenStateKit
//

import Testing
import SwiftUI
@testable import ScreenStateKit

@Suite("RMLoadmoreView Tests")
@MainActor
struct RMLoadmoreViewTests {

    // MARK: - Initialization

    @Test("init accepts LoadmoreScreenState")
    func test_init_acceptsLoadmoreScreenState() {
        let states = LoadmoreScreenState()
        let _ = RMLoadmoreView(states: states)
    }

    // MARK: - canExecuteLoadmore Integration

    @Test("canExecuteLoadmore sets canShowLoadmore when data not exhausted")
    func test_canExecuteLoadmore_setsCanShowLoadmore() {
        let states = LoadmoreScreenState()
        #expect(states.canShowLoadmore == false)

        states.canExecuteLoadmore()

        #expect(states.canShowLoadmore == true)
    }

    @Test("canExecuteLoadmore does not set canShowLoadmore when all data loaded")
    func test_canExecuteLoadmore_doesNotSetWhenAllDataLoaded() {
        let states = LoadmoreScreenState()
        states.updateDidLoadAllData(true)

        states.canExecuteLoadmore()

        #expect(states.canShowLoadmore == false)
    }
}

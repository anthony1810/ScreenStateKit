//
//  LoadmoreScreenStatesTests.swift
//  ScreenStatetKit
//

import Testing
@testable import ScreenStateKit

@Suite("LoadmoreScreenStates Tests")
@MainActor
struct LoadmoreScreenStatesTests {
    
    @Test("init starts with canShowLoadmore false and didLoadAllData false")
    func test_init_startsWithDefaultValues() {
        let sut = LoadmoreScreenStates()

        #expect(sut.canShowLoadmore == false)
        #expect(sut.didLoadAllData == false)
    }

    @Test("canExecuteLoadmore sets canShowLoadmore to true when didLoadAllData is false")
    func test_canExecuteLoadmore_setsCanShowLoadmoreTrue() {
        let sut = LoadmoreScreenStates()

        sut.canExecuteLoadmore()

        #expect(sut.canShowLoadmore == true)
    }

    @Test("canExecuteLoadmore does nothing when didLoadAllData is true")
    func test_canExecuteLoadmore_doesNothingWhenDidLoadAllData() {
        let sut = LoadmoreScreenStates()
        sut.updateDidLoadAllData(true)

        sut.canExecuteLoadmore()

        #expect(sut.canShowLoadmore == false)
    }
    
    @Test("updateDidLoadAllData(true) sets didLoadAllData true and canShowLoadmore false")
    func test_updateDidLoadAllData_true_setsDidLoadAllDataAndHidesLoadmore() {
        let sut = LoadmoreScreenStates()
        sut.canExecuteLoadmore() // Set canShowLoadmore to true first

        sut.updateDidLoadAllData(true)

        #expect(sut.didLoadAllData == true)
        #expect(sut.canShowLoadmore == false)
    }

    
    @Test("ternimateLoadmoreView sets canShowLoadmore to false")
    func test_terminateLoadmoreView_setsCanShowLoadmoreFalse() {
        let sut = LoadmoreScreenStates()
        sut.canExecuteLoadmore() // First set it to true
        #expect(sut.canShowLoadmore == true)

        sut.ternimateLoadmoreView()

        #expect(sut.canShowLoadmore == false)
    }
    
    @Test("updateDidLoadAllData(false) sets didLoadAllData false and canShowLoadmore true")
    func test_updateDidLoadAllData_false_clearsDidLoadAllDataAndShowsLoadmore() {
        let sut = LoadmoreScreenStates()
        sut.updateDidLoadAllData(true) // First exhaust data
        #expect(sut.didLoadAllData == true)

        sut.updateDidLoadAllData(false)

        #expect(sut.didLoadAllData == false)
        #expect(sut.canShowLoadmore == true)
    }

}

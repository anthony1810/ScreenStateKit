//
//  OnShowErrorModifierTests.swift
//  ScreenStateKit
//

import Testing
import SwiftUI
@testable import ScreenStateKit

@Suite("OnShowErrorModifier Tests")
@MainActor
struct OnShowErrorModifierTests {

    // MARK: - DisplayableError Integration

    @Test("error message returns custom message")
    func test_errorMessage_returnsCustomMessage() {
        let error = DisplayableError(message: "Network timeout")
        #expect(error.message == "Network timeout")
        #expect(error.errorDescription == "Network timeout")
    }

    @Test("error conforms to Identifiable with unique id")
    func test_error_hasUniqueId() {
        let error1 = DisplayableError(message: "Error 1")
        let error2 = DisplayableError(message: "Error 2")
        #expect(error1.id != error2.id)
    }

    @Test("error conforms to Hashable")
    func test_error_isHashable() {
        let error = DisplayableError(message: "Test")
        var set = Set<DisplayableError>()
        set.insert(error)
        #expect(set.contains(error))
    }
}

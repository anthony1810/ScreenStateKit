//
//  LoadmoreScreenStates.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//
import SwiftUI
import Combine

//MARK: - Loadmore Screen States
@available(macOS 10.15, *)
open class LoadmoreScreenStates: ScreenStates {
    
    @Published public private(set) var canShowLoadmore: Bool = false
    @Published public private(set) var didLoadAllData: Bool = false
    
    public func ternimateLoadmoreView() {
        withAnimation {
            self.canShowLoadmore = false
        }
    }
    
    public func canExecuteLoadmore() {
        guard !didLoadAllData else { return }
        withAnimation {
            self.canShowLoadmore = true
        }
    }
    
    public func updateDidLoadAllData(_ didLoadAllData: Bool) {
        withAnimation {
            self.didLoadAllData = didLoadAllData
            self.canShowLoadmore = !didLoadAllData
        }
    }
}

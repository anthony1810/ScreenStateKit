//
//  RMLoadmoreView.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import SwiftUI

public struct RMLoadmoreView: View {
    
    var states: LoadmoreScreenState

    public init(states: LoadmoreScreenState) {
        self.states = states
    }
    
    public var body: some View {
        ProgressView()
            .id(UUID())
            .progressViewStyle(.circular)
            .tint(.primary)
            .frame(maxWidth: .infinity, maxHeight: 20)
            .listRowBackground(Color.clear)
            .onDisappear {
                states.canExecuteLoadmore()
            }
    }
}

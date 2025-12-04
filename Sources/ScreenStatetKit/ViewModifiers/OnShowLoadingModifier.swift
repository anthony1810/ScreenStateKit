//
//  OnShowLoadingModifier.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import SwiftUI

struct OnShowLoadingModifier: ViewModifier {
    
    @Binding var isLoading: Bool

    func body(content: Content) -> some View {
        content
            .overlay(content: {
                ProgressView()
                    .frame(width: 50.0, height: 50.0)
                    .opacity(isLoading ? 1 : 0)
                    .animation(.easeInOut, value: isLoading)
            })
    }
}

struct OnShowBlockLoadingModifier: ViewModifier {
    
    @Binding var isLoading: Bool
    let subtitle: String?
    
    func body(content: Content) -> some View {
        content
            .overlay(content: {
                VStack(alignment: .center) {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.05))
                .opacity(isLoading ? 1 : 0)
                .animation(.easeInOut, value: isLoading)
            })
    }
}

extension View {
    public func onShowLoading(_ isLoading: Binding<Bool>) -> some View {
        modifier(OnShowLoadingModifier(isLoading: isLoading))
    }
    
    public func onShowBlockLoading(_ isLoading: Binding<Bool>, subtitles: String? = nil) -> some View {
        modifier(OnShowBlockLoadingModifier(isLoading: isLoading, subtitle: subtitles))
    }
}


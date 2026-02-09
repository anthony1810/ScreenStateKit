//
//  OnShowErrorModifier.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//
import SwiftUI
struct OnShowErrorModifier: ViewModifier {
    
    @State private var isPresentAlert: Bool = false
    @Binding var error: DisplayableError?
    
    private var errorMessage: String {
        error?.message ?? "Something went wrong."
    }
    
    func body(content: Content) -> some View {
        content
            .alert("", isPresented: $isPresentAlert) {
                
            } message: {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.primary)
            }
            .onChange(of: isPresentAlert) {
                // When the alert is dismissed, reset the error.
                if !isPresentAlert {
                    error = nil
                }
            }
            .onChange(of: error) {
                // When a new error is set, show the alert.
                if error != nil && !isPresentAlert {
                    isPresentAlert = true
                }
            }
    }
}


extension View {
    public func onShowError(_ error: Binding<DisplayableError?>) -> some View {
        modifier(OnShowErrorModifier(error: error))
    }
}

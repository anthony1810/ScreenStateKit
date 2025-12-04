//
//  OnShowErrorModifier.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//
import SwiftUI

@available(macOS 10.15, *)
struct OnShowErrorModifier: ViewModifier {
    
    @State private var isPresentAlert: Bool = false
    @Binding var error: RMDisplayableError?
    
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
            .onChange(of: isPresentAlert, perform: { newValue in
                guard !newValue else { return }
                error = .none
            })
            .onChange(of: error) { newValue in
                guard newValue != nil && !isPresentAlert else { return }
                self.isPresentAlert = true
            }
    }
}

@available(macOS 10.15, *)
extension View {
    public func onShowError(_ error: Binding<RMDisplayableError?>) -> some View {
        modifier(OnShowErrorModifier(error: error))
    }
}

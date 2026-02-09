//
//  PlaceholderModifier.swift
//  ScreenStateKit
//

import SwiftUI

/// A view modifier that applies `.redacted(reason: .placeholder)` when the value is a placeholder.
struct PlaceholderModifier<T: PlaceholderRepresentable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        content
            .redacted(reason: value.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - View Extension

public extension View {
    /// Applies `.redacted(reason: .placeholder)` when the value is a placeholder.
    ///
    /// Usage:
    /// ```swift
    /// ForEach(viewState.snapshot.words) { word in
    ///     WordCardView(word: word)
    /// }
    /// .placeholder(viewState.snapshot)
    /// .shimmering(active: viewState.snapshot.isPlaceholder)
    /// ```
    func placeholder<T: PlaceholderRepresentable>(_ value: T) -> some View {
        modifier(PlaceholderModifier(value: value))
    }
}

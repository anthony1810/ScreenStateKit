//
//  PlaceholderRepresentable.swift
//  ScreenStateKit
//

import Foundation

/// A protocol for types that can provide placeholder data for skeleton loading effects.
///
/// Conform to this protocol to enable skeleton loading with `.redacted()` and `.shimmering()`.
///
/// Example usage:
/// ```swift
/// struct HomeSnapshot: Equatable, PlaceholderRepresentable {
///     let items: [Item]
///
///     static var placeholder: HomeSnapshot {
///         HomeSnapshot(items: Item.mocks)
///     }
///
///     var isPlaceholder: Bool { self == .placeholder }
/// }
/// ```
public protocol PlaceholderRepresentable {
    /// The placeholder instance used for skeleton loading.
    static var placeholder: Self { get }

    /// Returns `true` if this instance is the placeholder.
    var isPlaceholder: Bool { get }
}

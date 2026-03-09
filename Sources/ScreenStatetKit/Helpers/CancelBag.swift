//
//  CancelBag.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//

import Foundation
import SwiftUI

/// A container that manages the lifetime of `Task`s.
///
/// Tasks stored in a ``CancelBag`` can be cancelled individually using an
/// identifier or all at once using ``cancelAll()``.
///
/// When a task finishes (successfully or with cancellation), it is automatically
/// removed from the bag.
///
/// If the ``CancelBag`` is tied to the lifetime of a view or object, all stored
/// tasks will be cancelled when the bag is deallocated.
public actor CancelBag {

    private let storage: CancelBagStorage
    
    public var isEmpty: Bool {
        storage.isEmpty
    }
    
    public var count: Int {
        storage.count
    }
    
    public init() {
        storage = .init()
    }
    
    /// Cancels all stored tasks and clears the bag.
    public func cancelAll() {
        storage.cancelAll()
    }
    
    /// Cancels the task associated with the given identifier.
    ///
    /// - Parameter identifier: The identifier used when storing the task.
    public func cancel(forIdentifier identifier: AnyHashable) {
        storage.cancel(forIdentifier: identifier)
    }
    
    /// Appends a canceller to the bag.
    ///
    /// This method is nonisolated so tasks can store themselves without
    /// requiring the caller to `await`.
    private func insert(_ canceller: Canceller) {
        storage.insert(canceller: canceller)
    }
    
    /// Waits for the task to finish and removes it from storage.
    ///
    /// This ensures completed tasks do not remain in the bag.
    private func watch(_ canceller: Canceller) async {
        await canceller.waitResult()
        storage.remove(by: canceller.watchId)
    }
    
    nonisolated fileprivate func append(canceller: Canceller) {
        Task {[weak self] in
            await self?.insert(canceller)
            await self?.watch(canceller)
        }
    }
}

//MARK: - Storage
private final class CancelBagStorage {
    
    private var cancellers: [AnyHashable: Canceller] = [:]
    
    var isEmpty: Bool {
        cancellers.isEmpty
    }
    
    var count: Int {
        cancellers.count
    }
    
    func cancelAll() {
        let runningTasks = cancellers.values.filter({ !$0.isCancelled })
        runningTasks.forEach{ $0.cancel() }
        cancellers.removeAll()
    }
    
    func cancel(forIdentifier identifier: AnyHashable) {
        guard let task = cancellers[identifier] else { return }
        task.cancel()
        cancellers.removeValue(forKey: identifier)
    }
    
    func remove(by watchId: UUID) {
        guard let key = cancellers.first(where: { $0.value.watchId == watchId })?.key else { return }
        cancellers.removeValue(forKey: key)
    }
    
    func insert(canceller: Canceller) {
        cancel(forIdentifier: canceller.id)
        guard !canceller.isCancelled else { return }
        cancellers.updateValue(canceller, forKey: canceller.id)
    }
    
    deinit {
        cancelAll()
    }
}


//MARK: - Canceller
private struct Canceller {
    
    let cancel: @Sendable () -> Void
    let waitResult: @Sendable () async -> Void
    let id: AnyHashable
    let watchId: UUID
    var isCancelled: Bool { isCancelledBock() }
    
    private let isCancelledBock: @Sendable () -> Bool
    
    init<S,E>(_ task: Task<S,E>, identifier: AnyHashable) {
        cancel = { task.cancel() }
        waitResult = { _ = await task.result }
        isCancelledBock = { task.isCancelled }
        id = identifier
        watchId = .init()
    }
}

//MARK: - Short Path
extension Task {
    
    public func store(in bag: CancelBag?) {
        let canceller = Canceller(self, identifier: .init(UUID()))
        bag?.append(canceller: canceller)
    }
    
    public func store(in bag: CancelBag?, withIdentifier identifier: any Hashable) {
        let canceller = Canceller(self, identifier: .init(identifier))
        bag?.append(canceller: canceller)
    }
}

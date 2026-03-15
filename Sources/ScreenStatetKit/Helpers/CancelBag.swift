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
public actor CancelBag: ObservableObject {

    private let storage: CancelBagStorage
    
    public var isEmpty: Bool {
        storage.isEmpty
    }
    
    public var count: Int {
        storage.count
    }
    
    public var policy: DuplicatePolicy {
        storage.duplicatePolicy
    }
    
    public init(onDuplicate policy: DuplicatePolicy) {
        self.storage = .init(onDuplicate: policy)
    }
    
    /// Cancels all stored tasks and clears the bag.
    public func cancelAll() {
        storage.cancelAll()
    }
    
    @available(*, deprecated, renamed: "cancelAll", message: "CancelBag will automatically cancel all tasks when deallocated. No need call this method directly.")
    nonisolated public func cancelAllInTask() {
        Task(priority: .high) {
            await cancelAll()
        }
    }
    
    /// Cancels the task associated with the given identifier.
    ///
    /// - Parameter identifier: The identifier used when storing the task.
    public func cancel(forIdentifier identifier: AnyHashable) {
        storage.cancel(forIdentifier: identifier)
    }
    
    /// Appends a task to the bag.
    ///
    /// This method is nonisolated so tasks can store themselves without
    /// requiring the caller to `await`.
    private func insert(_ task: AnyTask) {
        storage.insert(task: task)
    }
    
    /// This ensures completed tasks do not remain in the bag.
    /// - Parameter watchId: ``Canceller``'s `watchId`
    private func removeCanceller(by watchId: UUID) async {
        storage.remove(by: watchId)
    }
    
    nonisolated fileprivate func append(task: AnyTask) {
        if #available(iOS 26.0, *) {
            Task.immediate {[weak self] in
                await self?.insert(task)
                await task.waitComplete()
                await self?.removeCanceller(by: task.watchId)
            }
        } else {
            Task {[weak self] in
                await self?.insert(task)
                await task.waitComplete()
                await self?.removeCanceller(by: task.watchId)
            }
        }
    }
}

extension CancelBag {
    
    /// Defines how `CancelBag` handles tasks with the same identifier.
    public enum DuplicatePolicy: Int8, Sendable {
        
        //// Cancel the currently executing task if a new task with the same identifier is added.
        case cancelExisting
        
        /// Cancel the newly added task if a task with the same identifier already exists.
        case cancelNew
    }
}

//MARK: - Storage
private final class CancelBagStorage {
    
    private var runningTasks: [AnyHashable: AnyTask]
    let duplicatePolicy: CancelBag.DuplicatePolicy
    
    var isEmpty: Bool {
        runningTasks.isEmpty
    }
    
    var count: Int {
        runningTasks.count
    }
    
    init(onDuplicate policy: CancelBag.DuplicatePolicy) {
        self.runningTasks = .init()
        self.duplicatePolicy = policy
    }
    
    func cancelAll() {
        runningTasks.values.forEach{ $0.cancel() }
        runningTasks.removeAll()
    }
    
    func cancel(forIdentifier identifier: AnyHashable) {
        guard let task = runningTasks[identifier] else { return }
        task.cancel()
        runningTasks.removeValue(forKey: identifier)
    }
    
    func remove(by watchId: UUID) {
        guard let key = runningTasks.first(where: { $0.value.watchId == watchId })?.key else { return }
        runningTasks.removeValue(forKey: key)
    }
    
    func insert(task: AnyTask) {
        guard let existing = runningTasks[task.storageKey] else {
            _insert(task: task)
            return
        }
        switch duplicatePolicy {
        case .cancelExisting:
            existing.cancel()
            runningTasks.removeValue(forKey: existing.storageKey)
            _insert(task: task)
        case .cancelNew:
            task.cancel()
        }
    }
    
    private func _insert(task: AnyTask) {
        guard !task.isCancelled else { return }
        runningTasks.updateValue(task, forKey: task.storageKey)
    }
    
    deinit {
        cancelAll()
    }
}


//MARK: - AnyTask
public struct AnyTask: Sendable {
    
    public typealias Identifier = Hashable & Sendable
    public let cancel: @Sendable () -> Void
    public let waitComplete: @Sendable () async -> Void
    public var isCancelled: Bool { isCancelledBock() }
    public let id: any Identifier
    
    let watchId: UUID
    private let isCancelledBock: @Sendable () -> Bool
    
    var storageKey: AnyHashable {
        .init(self.id)
    }
    
    init<S,E>(_ task: Task<S,E>, identifier: any Identifier) {
        cancel = { task.cancel() }
        waitComplete = { _ = await task.result }
        isCancelledBock = { task.isCancelled }
        id = identifier
        watchId = .init()
    }
}

//MARK: - Short Path
extension Task {
    
    @discardableResult
    public func store(in bag: CancelBag?) -> AnyTask {
        let anyTask = AnyTask(self, identifier: UUID())
        bag?.append(task: anyTask)
        return anyTask
    }
    
    @discardableResult
    public func store<Identifier>(in bag: CancelBag?,
                                  withIdentifier identifier: Identifier)
    -> AnyTask where Identifier: Hashable, Identifier: Sendable {
        let anyTask = AnyTask(self, identifier: identifier)
        bag?.append(task: anyTask)
        return anyTask
    }
}


//
//  CancelBag.swift
//  ScreenStatetKit
//
//  Created by Anthony on 4/12/25.
//



import Foundation

public actor CancelBag {

    private var cancellers: [String:Canceller]
    
    public init() {
        cancellers = .init()
    }
    
    public func cancelAll() {
        let runningTasks = cancellers.values.filter({ !$0.isCancelled })
        runningTasks.forEach{ $0.cancel() }
        cancellers.removeAll()
    }
    
    public func cancel(forIdentifier identifier: String) {
        guard let task = cancellers[identifier] else { return }
        task.cancel()
        cancellers.removeValue(forKey: identifier)
    }
    
    nonisolated public func cancelAllInTask() {
        Task(priority: .high) {
            await cancelAll()
        }
    }
    
    private func store(_ canceller: Canceller) {
        cancel(forIdentifier: canceller.id)
        guard !canceller.isCancelled else { return }
        cancellers.updateValue(canceller, forKey: canceller.id)
    }
    
    nonisolated fileprivate func append(canceller: Canceller) {
        Task(priority: .high) {
            await store(canceller)
        }
    }
}

private struct Canceller: Identifiable, Sendable {
    
    let cancel: @Sendable () -> Void
    let id: String
    var isCancelled: Bool { isCancelledBock() }
    
    private let isCancelledBock: @Sendable () -> Bool
    
    init<S,E>(_ task: Task<S,E>, identifier: String = UUID().uuidString) {
        cancel = { task.cancel() }
        isCancelledBock = { task.isCancelled }
        id = identifier
    }
}

extension Task {
    
    public func store(in bag: CancelBag) {
        let canceller = Canceller(self)
        bag.append(canceller: canceller)
    }
    
    public func store(in bag: CancelBag, withIdentifier identifier: String) {
        let canceller = Canceller(self, identifier: identifier)
        bag.append(canceller: canceller)
    }
}

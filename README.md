# ScreenStateKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17+-blue.svg)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14+-blue.svg)](https://developer.apple.com/macos/)
[![Tests](https://github.com/anthony1810/ScreenStateKit/actions/workflows/tests.yml/badge.svg)](https://github.com/anthony1810/ScreenStateKit/actions/workflows/tests.yml)
[![Fully Tested](https://img.shields.io/badge/coverage-fully%20tested-brightgreen)](https://github.com/anthony1810/ScreenStateKit/tree/main/Tests)

A comprehensive, fully tested Swift state management and UI toolkit for iOS 17+ applications built with SwiftUI. This framework provides reactive state containers, async action handling, task lifecycle management, and pre-built UI components for common patterns like loading states, error handling, and pagination.

**Main Contributor:** [@ThangKM](https://github.com/ThangKM)

## Sample Project

Check out the [Definery](https://github.com/anthony1810/Definery) app for a real-world example of ScreenStateKit in action.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Complete Feature Example](#complete-feature-example)
- [View Modifiers](#view-modifiers)
- [Environment CRUD Callbacks](#environment-crud-callbacks)
- [AsyncAction](#asyncaction)
- [Async Streaming](#async-streaming)
- [License](#license)

---

## Requirements

- iOS 17.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/ScreenStateKit.git", from: "1.0.0")
]
```

---

## Architecture Overview

ScreenStateKit promotes a clean architecture pattern for building features with three core components:

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI View                         │
│  - Owns @State for ViewState and ViewModel                  │
│  - Binds state to ViewModel in .task modifier               │
│  - Dispatches actions via viewModel.receive(action:)        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ binds & dispatches
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              ViewModel / Store (Actor)                      │
│  - Conforms to ScreenActionStore protocol                   │
│  - Holds weak reference to state                            │
│  - Processes actions with ActionLocker                      │
│  - Updates state on @MainActor                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ updates
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ViewState (Observable)                   │
│  - Extends ScreenState                                      │
│  - @Observable @MainActor class                             │
│  - Contains all UI state properties                         │
│  - Inherits loading/error handling                          │
└─────────────────────────────────────────────────────────────┘
```

### The Three Pillars

1. **State** (`ScreenState` subclass) - Observable state container that holds all UI-related data
2. **Action Dispatcher** (`ScreenActionStore` conforming actor) - ViewModel or Store that processes actions
3. **View** - SwiftUI view that binds state to dispatcher and triggers actions

---

## Complete Feature Example

Here's a complete example showing how to build a feature using ScreenStateKit's architecture:

### 1. Define the State

```swift
import Foundation
import ScreenStateKit
import Observation

@Observable @MainActor
final class FeatureViewState: LoadmoreScreenState, StateUpdatable {
    // UI Configuration
    let headerHeight: CGFloat = 120.0

    // Data State
    var items: [Item] = []
}
```

### 2. Define the ViewModel/Store

```swift
import Foundation
import ScreenStateKit

actor FeatureViewStore: ScreenActionStore {
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol

    // MARK: - State Management
    private let actionLocker = ActionLocker()
    weak var viewState: FeatureViewState?

    // MARK: - Init
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Actions
    enum Action: ActionLockable, LoadingTrackable, Sendable {
        case fetchItems
        case loadMore

        var canTrackLoading: Bool {
            switch self {
            case .fetchItems:
                return true
            case .loadMore:
                return false
            }
        }
    }

    // MARK: - ScreenActionStore Protocol
    func binding(state: FeatureViewState) {
        self.viewState = state
    }

    nonisolated func receive(action: Action) {
        Task {
            do {
                try await isolatedReceive(action: action)
            } catch {
                await viewState?.showError(
                    RMDisplayableError(message: error.localizedDescription)
                )
            }
        }
    }

    // MARK: - Action Processing
    func isolatedReceive(action: Action) async throws {
        guard await actionLocker.canExecute(action) else { return }
        await viewState?.loadingStarted(action: action)

        switch action {
        case .fetchItems:
            try await fetchItems()
        case .loadMore:
            try await loadMoreItems()
        }

        await actionLocker.unlock(action)
        await viewState?.loadingFinished(action: action)
    }

    // MARK: - Action Implementations
    private func fetchItems() async throws {
        let result = try await dataService.fetchItems(page: 1, limit: 20)
        await viewState?.updateState { state in
            state.items = result.items
        }
    }

    private func loadMoreItems() async throws {
        let currentItems = await viewState?.items ?? []
        let result = try await dataService.fetchItems(page: 2, limit: 20)
        await viewState?.updateState { state in
            state.items = currentItems + result.items
        }
    }
}
```

### 3. Build the View

```swift
import SwiftUI
import ScreenStateKit

struct FeatureView: View {
    // MARK: - State
    @State private var viewState: FeatureViewState
    @State private var viewStore: FeatureViewStore

    // MARK: - Init
    init(viewState: FeatureViewState, viewStore: FeatureViewStore) {
        self.viewState = viewState
        self.viewStore = viewStore
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            contentBody()
        }
        .onShowLoading($viewState.isLoading)
        .onShowError($viewState.displayError)
        .task {
            // Critical: Bind state to viewStore
            await viewStore.binding(state: viewState)

            // Initial data fetch
            viewStore.receive(action: .fetchItems)
        }
    }

    // MARK: - Content
    @ViewBuilder
    private func contentBody() -> some View {
        if viewState.items.isEmpty && !viewState.isLoading {
            emptyStateView()
        } else {
            itemListView()
        }
    }

    private func itemListView() -> some View {
        List {
            ForEach(viewState.items) { item in
                ItemRow(item: item)
            }

            // Load more indicator
            if !viewState.items.isEmpty && viewState.canShowLoadmore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        viewStore.receive(action: .loadMore)
                    }
            }
        }
        .refreshable {
            try? await viewStore.isolatedReceive(action: .fetchItems)
        }
    }

    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Items")
                .font(.title2)

            Text("Pull down to refresh")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

## View Modifiers

### .onShowError

Automatically displays error alerts when error state changes.

```swift
.onShowError($viewState.displayError)
```

### .onShowLoading

Shows centered circular progress indicator with opacity animation.

```swift
.onShowLoading($viewState.isLoading)
```

### .onShowBlockLoading

Shows full-screen semi-transparent loading overlay that blocks interaction.

```swift
.onShowBlockLoading($viewState.isLoading, subtitles: "Saving...")
```

---

## Environment CRUD Callbacks

Environment-based action callbacks for passing actions down the view hierarchy. Perfect for CRUD operations where child views need to notify parents of changes.

**Available Modifiers:**
| Modifier | Description |
|----------|-------------|
| `.onEdited(_ action:)` | Set edited callback |
| `.onDeleted(_ action:)` | Set deleted callback |
| `.onCreated(_ action:)` | Set created callback |
| `.onCancelled(_ action:)` | Set cancelled callback |

### Parent Setting Callbacks

```swift
struct ItemListView: View {
    @State private var viewState = ItemListViewState()
    @State private var viewModel: ItemListViewModel
    @State private var showCreateSheet = false
    @State private var selectedItem: Item?

    var body: some View {
        List(viewState.items) { item in
            ItemRow(item: item)
                .onTapGesture { selectedItem = item }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateItemView()
        }
        .sheet(item: $selectedItem) { item in
            EditItemView(item: item)
        }
        // Parent sets callbacks for child views to trigger
        .onCreated { [weak viewModel] in
            viewModel?.receive(action: .refreshItems)
        }
        .onEdited { [weak viewModel] in
            viewModel?.receive(action: .refreshItems)
        }
        .onDeleted { [weak viewModel] in
            viewModel?.receive(action: .refreshItems)
        }
    }
}
```

### Child Consuming Callbacks

```swift
struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.onEditedAction) private var onEditedAction
    @Environment(\.onDeletedAction) private var onDeletedAction
    @Environment(\.onCancelledAction) private var onCancelledAction

    let item: Item
    @State private var editedName: String
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item Name", text: $editedName)

                Button("Delete Item", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancelledAction?.execute()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateItem()
                            await onEditedAction?.asyncExecute()
                            dismiss()
                        }
                    }
                }
            }
            .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteItem()
                        await onDeletedAction?.asyncExecute()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
```

---

## AsyncAction

A generic wrapper for async/await operations with configurable input and output types.

**Type Aliases:**
| Alias | Definition | Use Case |
|-------|------------|----------|
| `AsyncActionVoid` | `AsyncAction<Void, Void>` | No input, no output |
| `AsyncActionGet<Output>` | `AsyncAction<Void, Output>` | No input, returns output |
| `AsyncActionPut<Input>` | `AsyncAction<Input, Void>` | Takes input, no output |

### Examples

```swift
// Fire and forget action
let refreshAction: AsyncActionVoid = .init {
    await dataStore.refresh()
}
refreshAction.execute()

// Action that returns data
let getSettings: AsyncActionGet<Settings> = .init {
    return await settingsManager.currentSettings
}
let settings = try await getSettings.asyncExecute()

// Action that takes input but returns nothing
let saveItem: AsyncActionPut<Item> = .init { item in
    await itemStore.save(item)
}
saveItem.execute(myItem)

// Full input/output action
let fetchUser: AsyncAction<String, User> = .init { userId in
    return try await userService.fetchUser(id: userId)
}
let user = try await fetchUser.asyncExecute("user-123")
```

---

## Async Streaming

### StreamProducer

A multi-consumer async event emitter (actor-based) that allows multiple subscribers to receive events.

```swift
// Create a stream producer
let eventProducer = StreamProducer<UserEvent>()

// Emit events from anywhere
await eventProducer.emit(element: .userLoggedIn(user))
await eventProducer.emit(element: .profileUpdated(profile))

// Subscribe to events
Task {
    for await event in await eventProducer.stream {
        switch event {
        case .userLoggedIn(let user):
            print("User logged in: \(user.name)")
        case .profileUpdated(let profile):
            print("Profile updated")
        }
    }
}

// Finish the stream when done
await eventProducer.finish()
```

### CancelBag

Manages and cancels multiple async tasks. Essential for cleanup in actors and view models.

```swift
actor MyViewModel {
    private let cancelBag = CancelBag()
    private let eventProducer = StreamProducer<DataEvent>()

    deinit {
        cancelBag.cancelAllInTask()
    }

    func startObserving() {
        // Store task with identifier for later cancellation
        Task.detached { [weak self] in
            guard let stream = await self?.eventProducer.stream else { return }
            for await event in stream {
                await self?.handleEvent(event)
            }
        }.store(in: cancelBag, withIdentifier: "eventObserver")
    }

    func stopObserving() async {
        await cancelBag.cancel(forIdentifier: "eventObserver")
    }
}
```

### AnyAsyncStream

Type-erased wrapper for any `AsyncSequence`, useful for abstracting different stream types.

```swift
// Wrap any async sequence
let wrappedStream = someAsyncSequence.anyAsyncStream

// Use in generic contexts
func observe<T>(stream: AnyAsyncStream<T>) async {
    while let value = try? await stream.next() {
        process(value)
    }
}
```

---

## License

MIT License

---

## Acknowledgments

Built with Swift's modern concurrency features including `async/await`, actors, and the `@Observable` macro.

# ScreenStateKit Skill

Use this skill when building features in Swift apps that use ScreenStateKit for state management. ScreenStateKit provides the "Three Pillars" pattern: **State** (Observable) + **Store** (Actor ViewModel) + **View** (SwiftUI). Use it for creating screens with loading states, error handling, pagination, action deduplication, async streaming, task cancellation, and CRUD environment callbacks.

## Requirements

- iOS 17+ / macOS 14+
- Swift 5.9+
- Swift Package: `https://github.com/anthony1810/ScreenStateKit.git`

## Architecture: The Three Pillars

Every feature has three components:

1. **State** (`ScreenState` subclass) - `@Observable @MainActor` class holding all UI data
2. **Store** (actor conforming to `ScreenActionStore`) - Processes actions, updates state
3. **View** (SwiftUI) - Binds state, dispatches actions to store

The flow: **View** dispatches actions to **Store** via `receive(action:)` → **Store** processes action → **Store** updates **State** → **View** re-renders via `@Observable`.

---

## Pillar 1: State

### Basic ScreenState

```swift
import ScreenStateKit
import Observation

@Observable @MainActor
final class MyFeatureViewState: ScreenState, StateUpdatable {
    var items: [Item] = []
    var title: String = ""
}
```

Key rules:
- Always subclass `ScreenState` (or `LoadmoreScreenState` for pagination)
- Always add `@Observable @MainActor`
- Always conform to `StateUpdatable` for safe batched updates
- Mark as `final class`
- Use `var` for mutable properties the store will update

### Built-in State Properties (from ScreenState)

- `isLoading: Bool` - Driven by an internal counter (increment/decrement), not a simple toggle
- `displayError: DisplayableError?` - Setting this automatically resets `isLoading` to false
- `loadingStarted()` / `loadingFinished()` - Increment/decrement the loading counter
- `loadingStarted(action:)` / `loadingFinished(action:)` - Only affects counter if `action.canTrackLoading` is true
- `showError(_ error: LocalizedError)` - Wraps error into DisplayableError and sets it

### StateUpdatable

Conform to `StateUpdatable` to batch state updates with animation control:

```swift
// Default: animated with .smooth
await viewState?.updateState { state in
    state.items = newItems
    state.title = "Updated"
}

// With custom animation
await viewState?.updateState(withAnimation: .easeInOut) { state in
    state.items = newItems
}

// Without animation
await viewState?.updateState(withAnimation: .none) { state in
    state.items = newItems
}
```

### LoadmoreScreenState (Pagination)

```swift
@Observable @MainActor
final class ListViewState: LoadmoreScreenState, StateUpdatable {
    var items: [Item] = []
}
```

Additional properties and methods:
- `canShowLoadmore: Bool` (read-only) - Whether to show the load-more spinner
- `didLoadAllData: Bool` (read-only) - Whether all pages have been fetched
- `canExecuteLoadmore()` - Enables the loadmore indicator (no-op if `didLoadAllData` is true)
- `updateDidLoadAllData(_ didLoadAllData: Bool)` - Sets the exhaustion flag and toggles loadmore visibility
- `ternimateLoadmoreView()` - Hides the load-more indicator

### Parent-Child State Binding

Child state can propagate loading and/or error to a parent state:

```swift
@Observable @MainActor
final class ParentViewState: ScreenState, StateUpdatable { }

@Observable @MainActor
final class ChildViewState: ScreenState, StateUpdatable {
    init(parent: ParentViewState) {
        // Propagate both loading and error (default)
        super.init(states: parent)
    }
}

// Propagate loading only
final class ChildViewState: ScreenState, StateUpdatable {
    init(parent: ParentViewState) {
        super.init(states: parent, options: .loading)
    }
}

// Propagate error only
final class ChildViewState: ScreenState, StateUpdatable {
    init(parent: ParentViewState) {
        super.init(states: parent, options: .error)
    }
}
```

Options: `.loading`, `.error`, `.all` (default, both).

### PlaceholderRepresentable (Skeleton Loading)

```swift
struct HomeSnapshot: Equatable, PlaceholderRepresentable {
    let items: [Item]

    static var placeholder: HomeSnapshot {
        HomeSnapshot(items: Item.mocks)
    }

    var isPlaceholder: Bool { self == .placeholder }
}

// In state:
@Observable @MainActor
final class HomeViewState: ScreenState, StateUpdatable {
    var snapshot: HomeSnapshot = .placeholder  // Start with skeleton
}
```

---

## Pillar 2: Store (Actor ViewModel)

### Complete Store Template

```swift
import Foundation
import ScreenStateKit

actor FeatureViewStore: ScreenActionStore {
    // MARK: - State
    private weak var viewState: FeatureViewState?

    // MARK: - Dependencies
    private let actionLocker = ActionLocker.nonIsolated  // Use .nonIsolated inside actor
    private let service: SomeServiceProtocol

    // MARK: - Init
    init(service: SomeServiceProtocol) {
        self.service = service
    }

    // MARK: - Actions
    enum Action: ActionLockable, LoadingTrackable, Hashable {
        case fetchItems
        case loadMore
        case deleteItem(id: String)

        var canTrackLoading: Bool {
            switch self {
            case .fetchItems: return true
            case .loadMore: return false   // Don't show global loading for loadmore
            case .deleteItem: return true
            }
        }
    }

    // MARK: - ScreenActionStore Protocol
    func binding(state: FeatureViewState) {
        self.viewState = state
    }

    nonisolated func receive(action: Action) {
        Task {
            await isolatedReceive(action: action)
        }
    }

    // MARK: - Action Processing
    private func isolatedReceive(action: Action) async {
        guard actionLocker.canExecute(action) else { return }
        await viewState?.loadingStarted(action: action)

        do {
            switch action {
            case .fetchItems:
                try await fetchItems()
            case .loadMore:
                try await loadMoreItems()
            case .deleteItem(let id):
                try await deleteItem(id: id)
            }
        } catch let error as LocalizedError {
            await viewState?.showError(error)
        } catch {
            // Log non-LocalizedError silently
            debugPrint("\(declaredName): \(error.localizedDescription)")
        }

        actionLocker.unlock(action)
        await viewState?.loadingFinished(action: action)
    }

    // MARK: - Action Implementations
    private func fetchItems() async throws {
        let items = try await service.fetchItems(page: 1)
        await viewState?.updateState { state in
            state.items = items
        }
    }

    private func loadMoreItems() async throws {
        let currentItems = await viewState?.items ?? []
        let nextPage = currentItems.count / 20 + 1
        let newItems = try await service.fetchItems(page: nextPage)
        await viewState?.updateState { state in
            state.items = currentItems + newItems
        }
        await viewState?.ternimateLoadmoreView()
    }

    private func deleteItem(id: String) async throws {
        try await service.delete(id: id)
        let items = await viewState?.items ?? []
        await viewState?.updateState { state in
            state.items = items.filter { $0.id != id }
        }
    }
}
```

### Key Store Patterns

**ActionLocker variants:**
- `ActionLocker.nonIsolated` - Use inside an actor (the actor already provides isolation)
- `ActionLocker.isolated` - Use when shared across multiple concurrent contexts

**Action processing sequence (ALWAYS follow this order):**
1. `guard actionLocker.canExecute(action) else { return }` - Prevent duplicates
2. `await viewState?.loadingStarted(action: action)` - Start loading if trackable
3. Execute the action logic in a do-catch
4. `actionLocker.unlock(action)` - Release the lock
5. `await viewState?.loadingFinished(action: action)` - Stop loading if trackable

**Error handling pattern:**
```swift
do {
    // action logic
} catch let error as LocalizedError {
    await viewState?.showError(error)
} catch {
    debugPrint("\(declaredName): \(error.localizedDescription)")
}
```

Or with DisplayableError directly:
```swift
} catch {
    await viewState?.showError(DisplayableError(message: error.localizedDescription))
}
```

**Actions with associated values need custom lockKey:**
```swift
enum Action: ActionLockable, LoadingTrackable {
    case fetchUser(id: Int)
    case deleteUser(id: Int)

    var lockKey: AnyHashable {
        switch self {
        case .fetchUser: return "fetchUser"
        case .deleteUser: return "deleteUser"
        }
    }

    var canTrackLoading: Bool { true }
}
```

Actions that are `Hashable` without associated values get `lockKey` automatically via the protocol extension.

**Exposing isolatedReceive for testing and pull-to-refresh:**
```swift
// Make isolatedReceive internal (not private) so tests can call it directly
func isolatedReceive(action: Action) async { ... }

// In view, use for pull-to-refresh:
.refreshable {
    await viewStore.isolatedReceive(action: .fetchItems)
}
```

---

## Pillar 3: View

### Complete View Template

```swift
import SwiftUI
import ScreenStateKit

struct FeatureView: View {
    @State private var viewState: FeatureViewState
    @State private var viewStore: FeatureViewStore

    init(viewState: FeatureViewState, viewStore: FeatureViewStore) {
        self.viewState = viewState
        self.viewStore = viewStore
    }

    var body: some View {
        ZStack {
            contentBody()
        }
        .onShowLoading($viewState.isLoading)
        .onShowError($viewState.displayError)
        .task {
            await viewStore.binding(state: viewState)
            viewStore.receive(action: .fetchItems)
        }
    }

    @ViewBuilder
    private func contentBody() -> some View {
        if viewState.items.isEmpty && !viewState.isLoading {
            ContentUnavailableView("No Items", systemImage: "tray")
        } else {
            itemListView()
        }
    }

    private func itemListView() -> some View {
        List {
            ForEach(viewState.items) { item in
                ItemRow(item: item)
            }

            if viewState.canShowLoadmore {
                RMLoadmoreView(states: viewState)
                    .onAppear {
                        viewStore.receive(action: .loadMore)
                    }
            }
        }
        .refreshable {
            await viewStore.isolatedReceive(action: .fetchItems)
        }
    }
}
```

### View Integration Rules

1. **Bind state to store in `.task`**: Always call `await viewStore.binding(state: viewState)` first
2. **Dispatch initial action after binding**: `viewStore.receive(action: .fetchItems)`
3. **Apply view modifiers**:
   - `.onShowLoading($viewState.isLoading)` - Centered ProgressView overlay
   - `.onShowBlockLoading($viewState.isLoading, subtitles: "Saving...")` - Full-screen blocking overlay
   - `.onShowError($viewState.displayError)` - Alert for errors
   - `.placeholder(viewState.snapshot)` - Skeleton loading with `.redacted()`
4. **RMLoadmoreView**: Use for pagination, triggers `canExecuteLoadmore()` on disappear

### View Modifiers Reference

| Modifier | Purpose |
|----------|---------|
| `.onShowError($viewState.displayError)` | Shows alert when error is set |
| `.onShowLoading($viewState.isLoading)` | Shows centered ProgressView overlay |
| `.onShowBlockLoading($viewState.isLoading, subtitles:)` | Full-screen semi-transparent blocking overlay |
| `.placeholder(viewState.snapshot)` | Applies `.redacted(reason: .placeholder)` when isPlaceholder is true |

---

## AsyncAction

Generic wrapper for async closures with configurable Input and Output types.

### Type Aliases

| Alias | Definition | Use Case |
|-------|------------|----------|
| `AsyncActionVoid` | `AsyncAction<Void, Void>` | Fire and forget |
| `AsyncActionGet<Output>` | `AsyncAction<Void, Output>` | No input, returns output |
| `AsyncActionPut<Input>` | `AsyncAction<Input, Void>` | Takes input, no output |

### Usage

```swift
// Fire and forget
let refreshAction: AsyncActionVoid = .init {
    await dataStore.refresh()
}
refreshAction.execute()           // fire-and-forget
try await refreshAction.asyncExecute()  // awaitable

// Action that returns data
let getSettings: AsyncActionGet<Settings> = .init {
    return await settingsManager.currentSettings
}
let settings = try await getSettings.asyncExecute()

// Action that takes input
let saveItem: AsyncActionPut<Item> = .init { item in
    await itemStore.save(item)
}
saveItem.execute(myItem)

// Full input/output
let fetchUser: AsyncAction<String, User> = .init { userId in
    return try await userService.fetchUser(id: userId)
}
let user = try await fetchUser.asyncExecute("user-123")
```

### Passing AsyncAction as Dependency

```swift
// Parent injects action into child store
let startGameAction: AsyncActionVoid = .init { [weak self] in
    await self?.startGame()
}
let store = GameSetupStore(startGameAction: startGameAction)

// Inside the store
private let startGameAction: AsyncActionVoid

case .startGame:
    try await startGameAction.asyncExecute()
```

---

## Environment CRUD Callbacks

Pass action callbacks down the view hierarchy using SwiftUI Environment.

### Parent Sets Callbacks

```swift
struct ItemListView: View {
    @State private var viewStore: ItemListStore

    var body: some View {
        List { /* ... */ }
            .sheet(isPresented: $showCreate) {
                CreateItemView()
            }
            .sheet(item: $selectedItem) { item in
                EditItemView(item: item)
            }
            .onCreated { [weak viewStore] in
                viewStore?.receive(action: .refreshItems)
            }
            .onEdited { [weak viewStore] in
                viewStore?.receive(action: .refreshItems)
            }
            .onDeleted { [weak viewStore] in
                viewStore?.receive(action: .refreshItems)
            }
    }
}
```

### Child Consumes Callbacks

```swift
struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.onEditedAction) private var onEditedAction
    @Environment(\.onDeletedAction) private var onDeletedAction
    @Environment(\.onCancelledAction) private var onCancelledAction

    var body: some View {
        Form { /* ... */ }
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
                            await saveChanges()
                            await onEditedAction?.asyncExecute()
                            dismiss()
                        }
                    }
                }
            }
    }
}
```

Available environment keys: `\.onEditedAction`, `\.onDeletedAction`, `\.onCreatedAction`, `\.onCancelledAction` (all `AsyncActionVoid?`).

---

## StreamProducer (Multi-Subscriber Async Stream)

Actor-based event emitter supporting multiple concurrent subscribers.

```swift
// Create
let eventProducer = StreamProducer<UserEvent>()

// Emit events
await eventProducer.emit(element: .userLoggedIn(user))

// Subscribe (for await loop)
Task {
    for await event in await eventProducer.stream {
        handleEvent(event)
    }
}

// Finish (terminates all subscriber streams)
await eventProducer.finish()
```

### withLatest Option

```swift
// Default: withLatest = true, new subscribers get latest value immediately
let producer = StreamProducer<Int>(element: 0, withLatest: true)

// withLatest = false, new subscribers only get future values
let producer = StreamProducer<Int>(withLatest: false)
```

### Non-Isolated Methods (for deinit or nonisolated contexts)

```swift
producer.nonIsolatedEmit(.someEvent)
producer.nonIsolatedFinish()
```

---

## CancelBag (Task Lifecycle Management)

Actor that stores and manages Task cancellation by identifier.

```swift
actor MyStore {
    private let cancelBag = CancelBag()

    deinit {
        cancelBag.cancelAllInTask()  // Non-isolated cleanup in deinit
    }

    func startObserving() {
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

### Key Methods

- `task.store(in: cancelBag)` - Store with auto-generated identifier
- `task.store(in: cancelBag, withIdentifier: "id")` - Store with specific identifier (cancels any existing task with same id)
- `await cancelBag.cancelAll()` - Cancel all stored tasks
- `await cancelBag.cancel(forIdentifier: "id")` - Cancel specific task
- `cancelBag.cancelAllInTask()` - Non-isolated version for `deinit`

### Common Pattern: Observing Streams with CancelBag

```swift
private func observeChanges() {
    Task.detached { [weak self] in
        guard let stream = await self?.changeProducer.stream else { return }
        for await change in stream {
            await self?.handleChange(change)
        }
    }.store(in: cancelBag, withIdentifier: #function)
}
```

Use `#function` as identifier to auto-cancel if the method is called again.

---

## DisplayableError

```swift
public struct DisplayableError: LocalizedError, Identifiable, Hashable {
    public let id: String        // Auto-generated UUID
    public let message: String
    public var errorDescription: String? { message }

    public init(message: String)
}
```

---

## Complete Real-World Feature (Copy-Paste Template)

### State

```swift
import ScreenStateKit
import Observation

@Observable @MainActor
final class UserListViewState: LoadmoreScreenState, StateUpdatable {
    var users: [User] = []
    var searchQuery: String = ""
}
```

### Store

```swift
import Foundation
import ScreenStateKit

actor UserListViewStore: ScreenActionStore {
    private weak var viewState: UserListViewState?
    private let actionLocker = ActionLocker.nonIsolated
    private let cancelBag = CancelBag()
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    deinit {
        cancelBag.cancelAllInTask()
    }

    enum Action: ActionLockable, LoadingTrackable, Hashable {
        case fetchUsers
        case loadMore
        case search(query: String)
        case deleteUser(id: String)

        var canTrackLoading: Bool {
            switch self {
            case .fetchUsers: return true
            case .loadMore: return false
            case .search: return false
            case .deleteUser: return true
            }
        }
    }

    func binding(state: UserListViewState) {
        self.viewState = state
    }

    nonisolated func receive(action: Action) {
        Task { await isolatedReceive(action: action) }
    }

    func isolatedReceive(action: Action) async {
        guard actionLocker.canExecute(action) else { return }
        await viewState?.loadingStarted(action: action)

        do {
            switch action {
            case .fetchUsers:
                try await fetchUsers()
            case .loadMore:
                try await loadMoreUsers()
            case .search(let query):
                try await searchUsers(query: query)
            case .deleteUser(let id):
                try await deleteUser(id: id)
            }
        } catch let error as LocalizedError {
            await viewState?.showError(error)
        } catch {
            debugPrint("\(declaredName): \(error.localizedDescription)")
        }

        actionLocker.unlock(action)
        await viewState?.loadingFinished(action: action)
    }

    private func fetchUsers() async throws {
        let result = try await userService.fetchUsers(page: 1)
        await viewState?.updateState { state in
            state.users = result.users
        }
        await viewState?.updateDidLoadAllData(result.isLastPage)
    }

    private func loadMoreUsers() async throws {
        let currentUsers = await viewState?.users ?? []
        let nextPage = currentUsers.count / 20 + 1
        let result = try await userService.fetchUsers(page: nextPage)
        await viewState?.updateState { state in
            state.users = currentUsers + result.users
        }
        await viewState?.updateDidLoadAllData(result.isLastPage)
        await viewState?.ternimateLoadmoreView()
    }

    private func searchUsers(query: String) async throws {
        let users = try await userService.search(query: query)
        await viewState?.updateState { state in
            state.users = users
        }
    }

    private func deleteUser(id: String) async throws {
        try await userService.delete(id: id)
        let users = await viewState?.users ?? []
        await viewState?.updateState { state in
            state.users = users.filter { $0.id != id }
        }
    }
}
```

### View

```swift
import SwiftUI
import ScreenStateKit

struct UserListView: View {
    @State private var viewState = UserListViewState()
    @State private var viewStore: UserListViewStore

    init(userService: UserServiceProtocol) {
        self._viewStore = State(initialValue: UserListViewStore(userService: userService))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewState.users) { user in
                    UserRow(user: user)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                viewStore.receive(action: .deleteUser(id: user.id))
                            }
                        }
                }

                if viewState.canShowLoadmore {
                    RMLoadmoreView(states: viewState)
                        .onAppear {
                            viewStore.receive(action: .loadMore)
                        }
                }
            }
            .searchable(text: $viewState.searchQuery)
            .onChange(of: viewState.searchQuery) { _, newValue in
                viewStore.receive(action: .search(query: newValue))
            }
            .refreshable {
                await viewStore.isolatedReceive(action: .fetchUsers)
            }
            .navigationTitle("Users")
        }
        .onShowLoading($viewState.isLoading)
        .onShowError($viewState.displayError)
        .task {
            await viewStore.binding(state: viewState)
            viewStore.receive(action: .fetchUsers)
        }
    }
}
```

---

## Testing ViewStores

Use Swift Testing framework (`@Test`, `#expect`). Import `ConcurrencyExtras` for concurrency test helpers. ScreenStateKit internals (ActionLocker, CancelBag, ScreenState, StreamProducer) are already tested inside the framework — your tests focus on **your ViewStore's behavior**: action → state updates, error handling, action locking, loading tracking, and memory leaks.

### Test Dependencies

```swift
// In Package.swift testTarget
.product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
```

### Test File Structure

```
Tests/
├── Features/
│   └── Home/
│       └── HomeViewStoreTests.swift      // Tests for your ViewStore
├── Helpers/
│   ├── MemoryLeakTracker.swift           // Reusable leak detection
│   ├── Optional+Evaluate.swift           // Stub evaluation helper
│   ├── TestHelpers.swift                 // Factory methods (uniqueItem, anyNSError)
│   └── Spies/
│       └── ItemLoaderSpy.swift           // Spy for your dependency protocol
```

---

### Step 1: Create Test Helpers (reuse across all test files)

**MemoryLeakTracker.swift**
```swift
import Testing

struct MemoryLeakTracker {
    weak var instance: AnyObject?
    var sourceLocation: SourceLocation

    func verify() {
        #expect(
            instance == nil,
            "Expected \(String(describing: instance)) to be deallocated. Potential memory leak",
            sourceLocation: sourceLocation
        )
    }
}
```

**Optional+Evaluate.swift**
```swift
import Foundation

public extension Optional {
    /// Evaluates a Result stub. Fails immediately if stub was not set.
    func evaluate<T>(
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T where Wrapped == Result<T, Error> {
        switch self {
        case .some(let result):
            return try result.get()
        case .none:
            fatalError("Stub not set - did you forget to call complete(with:)?")
        }
    }
}
```

**TestHelpers.swift**
```swift
import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any", code: 0)
}

// Add your domain-specific factories:
func uniqueItem() -> Item {
    Item(id: UUID(), name: "item-\(UUID())")
}
```

---

### Step 2: Create a Spy for Your Dependency

A spy implements the same protocol your ViewStore depends on. It captures calls and lets you control return values via `complete(with:)`.

```swift
final class ItemLoaderSpy: ItemLoaderProtocol, @unchecked Sendable {
    private var result: Result<[Item], Error>?
    private(set) var loadCallCount = 0

    func load() async throws -> [Item] {
        loadCallCount += 1
        return try result.evaluate()
    }

    func complete(with result: Result<[Item], Error>) {
        self.result = result
    }
}
```

Key rules:
- Mark `@unchecked Sendable` so it can cross actor boundaries in tests
- Use `Result<T, Error>?` as stub — `evaluate()` will crash if you forget to set it
- Track `loadCallCount` to verify how many times the dependency was called
- Use `complete(with:)` to configure the stub before each test

For spies that need to track call sequences:
```swift
final class StorageSpy: StorageProtocol, @unchecked Sendable {
    enum ReceiveMessage: Equatable {
        case deletion
        case insertion([Item])
        case retrieve
    }

    var receiveMessages: [ReceiveMessage] = []
    private var deletionResult: Result<Void, Error>?

    func deleteCachedItems() async throws {
        receiveMessages.append(.deletion)
        try deletionResult.evaluate()
    }

    func completeDeletion(with result: Result<Void, Error>) {
        deletionResult = result
    }
}
```

---

### Step 3: Write Your ViewStore Tests

The test class is `@MainActor final class` (not struct) so `deinit` can verify memory leaks.

```swift
import Foundation
import Testing
import ScreenStateKit
import ConcurrencyExtras
@testable import YourApp

@MainActor
final class HomeViewStoreTests {
    private nonisolated(unsafe) var leakTrackers: [MemoryLeakTracker] = []

    deinit {
        leakTrackers.forEach { $0.verify() }
    }
```

#### The makeSUT Factory

Every test starts by calling `makeSUT()`. It creates the store, state, spy, wires them together, and tracks all objects for memory leaks.

```swift
    // MARK: - Helpers

    private func trackForMemoryLeaks(
        _ instance: AnyObject,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        leakTrackers.append(MemoryLeakTracker(instance: instance, sourceLocation: sourceLocation))
    }

    @MainActor
    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> (store: HomeViewStore, loader: ItemLoaderSpy, state: HomeViewState) {
        let loader = ItemLoaderSpy()
        let state = HomeViewState()
        let store = HomeViewStore(loader: loader)

        await store.binding(state: state)

        trackForMemoryLeaks(store, sourceLocation: sourceLocation)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(state, sourceLocation: sourceLocation)

        return (store, loader, state)
    }
}
```

---

### Test Patterns

#### Pattern 1: Init Does Not Trigger Side Effects

```swift
    @Test func init_doesNotLoadItems() async {
        let sut = await makeSUT()

        #expect(sut.loader.loadCallCount == 0)
    }
```

#### Pattern 2: Success Path (using `isolatedReceive`)

Use `isolatedReceive(action:)` for deterministic, synchronous-style tests. This calls the actor method directly and `await`s its completion.

```swift
    @Test func loadItems_deliversItemsOnLoaderSuccess() async {
        let sut = await makeSUT()
        let expectedItems = [uniqueItem()]

        sut.loader.complete(with: .success(expectedItems))
        await sut.store.isolatedReceive(action: .loadItems)

        #expect(sut.state.items == expectedItems)
    }
```

#### Pattern 3: Error Path (using `receive` + `withMainSerialExecutor`)

Use `receive(action:)` (the nonisolated public method) when testing the real async dispatch path. Wrap in `withMainSerialExecutor` and use `Task.megaYield()` to let the spawned Task complete.

```swift
    @Test func loadItems_deliversErrorOnLoaderFailure() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()

            sut.loader.complete(with: .failure(anyNSError()))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()

            #expect(sut.state.displayError != nil)
        }
    }
```

#### Pattern 4: Loading State Stops After Error

```swift
    @Test func loadItems_stopsLoadingOnError() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()

            sut.loader.complete(with: .failure(anyNSError()))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()

            #expect(sut.state.isLoading == false)
        }
    }
```

#### Pattern 5: Error Cleared on Subsequent Success

```swift
    @Test func loadItems_clearsErrorOnSuccess() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()

            // First trigger an error
            sut.loader.complete(with: .failure(anyNSError()))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()
            #expect(sut.state.displayError != nil)

            // Then load successfully
            sut.loader.complete(with: .success([]))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()
            #expect(sut.state.displayError == nil)
        }
    }
```

#### Pattern 6: Action Locking Prevents Duplicate Execution

```swift
    @Test func loadItems_doesNotRequestLoadTwiceWhilePending() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()

            sut.loader.complete(with: .success([]))

            async let first: () = sut.store.isolatedReceive(action: .loadItems)
            async let second: () = sut.store.isolatedReceive(action: .loadItems)

            _ = await (first, second)

            #expect(sut.loader.loadCallCount == 1)
        }
    }
```

#### Pattern 7: Load More Appends to Existing Data

```swift
    @Test func loadMore_appendsItemsToExistingItems() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()
            let initialItems = [uniqueItem(), uniqueItem()]
            let newItems = [uniqueItem()]

            sut.loader.complete(with: .success(initialItems))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()

            sut.loader.complete(with: .success(newItems))
            sut.store.receive(action: .loadMore)
            await Task.megaYield()

            #expect(sut.state.items == initialItems + newItems)
        }
    }
```

#### Pattern 8: Load More Preserves Existing Data on Error

```swift
    @Test func loadMore_keepsExistingItemsOnError() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()
            let initialItems = [uniqueItem(), uniqueItem()]

            sut.loader.complete(with: .success(initialItems))
            sut.store.receive(action: .loadItems)
            await Task.megaYield()

            sut.loader.complete(with: .failure(anyNSError()))
            sut.store.receive(action: .loadMore)
            await Task.megaYield()

            #expect(sut.state.items == initialItems)
        }
    }
```

#### Pattern 9: Load More Terminates Loadmore View on Error

```swift
    @Test func loadMore_terminatesLoadmoreViewOnError() async {
        await withMainSerialExecutor {
            let sut = await makeSUT()

            sut.state.canExecuteLoadmore()
            #expect(sut.state.canShowLoadmore == true)

            sut.loader.complete(with: .failure(anyNSError()))
            sut.store.receive(action: .loadMore)
            await Task.megaYield()

            #expect(sut.state.canShowLoadmore == false)
        }
    }
```

#### Pattern 10: Capturing Factory Arguments with LockIsolated

When your store uses a factory closure, capture what arguments were passed:

```swift
    @Test func loadItems_requestsLoaderWithCorrectLanguage() async {
        await withMainSerialExecutor {
            let capturedLanguages = LockIsolated<[Locale.LanguageCode]>([])
            let loader = ItemLoaderSpy()
            let store = HomeViewStore(loader: { language in
                capturedLanguages.withValue { $0.append(language) }
                return loader
            })
            let state = HomeViewState()
            await store.binding(state: state)

            loader.complete(with: .success([]))
            store.receive(action: .loadItems)
            await Task.megaYield()

            #expect(capturedLanguages.value == [.english])
        }
    }
```

---

### When to Use `isolatedReceive` vs `receive`

| Method | Use When | Requires |
|--------|----------|----------|
| `await store.isolatedReceive(action:)` | Simple action → state assertions. Deterministic, no Task spawning. | Nothing extra |
| `store.receive(action:)` | Testing real async dispatch, action locking with concurrent calls, or `nonisolated` entry point | `withMainSerialExecutor { }` + `await Task.megaYield()` |

Make `isolatedReceive` internal (not private) in your production store so tests can call it directly.

---

### What to Test in Every ViewStore

1. **Init does not trigger side effects** - No dependency calls on creation
2. **Success path** - Action delivers correct data to state
3. **Error path** - Action sets `displayError` on state
4. **Loading stops after error** - `isLoading == false` after failure
5. **Error cleared on success** - Subsequent success clears previous error
6. **Action locking** - Same action dispatched twice only executes once
7. **Load more appends** - New data appended, not replaced
8. **Load more preserves on error** - Existing data kept when loadmore fails
9. **Loadmore view terminated** - `canShowLoadmore` set to false after load
10. **Memory leaks** - All objects deallocated after test (automatic via `deinit`)

### Concurrency Utilities from `ConcurrencyExtras`

| Utility | Purpose |
|---------|---------|
| `withMainSerialExecutor { }` | Serializes all Tasks on main thread for deterministic test execution |
| `await Task.megaYield()` | Yields control to let spawned Tasks complete before asserting |
| `LockIsolated<T>` | Thread-safe value container for capturing data across actor boundaries |

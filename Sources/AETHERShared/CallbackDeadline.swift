import Foundation

/// One-shot bridge for callback APIs that do not support Swift task cancellation.
/// The lock protects only completion state; callbacks are resumed outside the lock.
public final class CallbackDeadline<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Value, any Error>?
    private var continuation: CheckedContinuation<Value, any Error>?
    private var timer: Task<Void, Never>?

    public init() {}

    /// Install before starting the external operation. False means it was already cancelled.
    @discardableResult
    public func install(_ continuation: CheckedContinuation<Value, any Error>, timeout: Duration) -> Bool {
        lock.lock()
        if let result {
            lock.unlock()
            continuation.resume(with: result)
            return false
        }
        guard self.continuation == nil else {
            lock.unlock()
            continuation.resume(throwing: AetherError.invalidState("Callback deadline already has a waiter"))
            return false
        }
        self.continuation = continuation
        timer = Task.detached { [weak self] in
            do {
                try await Task.sleep(for: timeout)
                self?.finish(.failure(AetherError.timeout("Callback operation exceeded its deadline")))
            } catch { /* Completion cancels the deadline timer. */ }
        }
        lock.unlock()
        return true
    }

    /// Returns false for late callbacks. Their owner must still release external resources.
    @discardableResult
    public func finish(_ result: Result<Value, any Error>) -> Bool {
        lock.lock()
        guard self.result == nil else { lock.unlock(); return false }
        self.result = result
        let continuation = self.continuation
        self.continuation = nil
        let timer = self.timer
        self.timer = nil
        lock.unlock()
        timer?.cancel()
        continuation?.resume(with: result)
        return true
    }
}
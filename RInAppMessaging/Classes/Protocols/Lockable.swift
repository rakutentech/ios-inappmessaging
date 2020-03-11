/// Protocol to mark object that have resources that can be thread locked
protocol Lockable {
    var resourcesToLock: [LockableResource] { get }
}

protocol LockableResource {

    /// Lock resource for caller's thread use
    func lock()

    /// Unlock resource. Access from other threads will be resumed
    func unlock()
}

/// Object-wrapper that conforms to LockableResource protocol.
/// Used to control getter and setter of given resource.
/// When lock() has been called on some thread, only that thread will be able to access the resource.
/// Other threads will synchronously wait for unlock() call to continue.
class LockableObject<T: Any>: LockableResource {

    private var resource: T
    private var lockingThread: Thread?
    private let dispatchGroup = DispatchGroup()

    init(_ resource: T) {
        self.resource = resource
    }

    func lock() {
        lockingThread = Thread.current
        dispatchGroup.enter()
    }

    func unlock() {
        lockingThread = nil
        dispatchGroup.leave()
    }

    func get() -> T {
        if let lockingThread = lockingThread, lockingThread != Thread.current {
            dispatchGroup.wait()
            return resource
        } else {
            return resource
        }
    }

    func set(value: T) {
        if let lockingThread = lockingThread, lockingThread != Thread.current {
            dispatchGroup.wait()
            resource = value
        } else {
            resource = value
        }
    }
}

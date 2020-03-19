internal protocol TaskSchedulable: AnyObject {

    // Save a reference to the work item in case of cancellation in the future.
    var scheduledTask: DispatchWorkItem? { get set }

    /// Schedules a task to be ran after a certain delay. Keeps reference of the `DispatchWorkItem`
    /// so that the work can be cancelled at any time.
    /// - Parameter milliseconds: Delay before running the task in milliseconds.
    /// - Parameter task: A block of code to run after the delay.
    /// - Parameter wallDeadline: Set `true` to use wall time (gettimeofday) instead of absolute time to ensure execution after returning from background
    func scheduleWorkItem(_ milliseconds: Int, task: DispatchWorkItem, wallDeadline: Bool)
}

/// Default implementation.
extension TaskSchedulable {
    func scheduleWorkItem(_ milliseconds: Int, task: DispatchWorkItem, wallDeadline: Bool) {

        scheduledTask?.cancel()
        scheduledTask = task
        if wallDeadline {
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(milliseconds), execute: task)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: task)
        }
    }
}

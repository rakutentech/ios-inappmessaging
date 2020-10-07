internal protocol TaskSchedulable: AnyObject {

    // Save a reference to the work item in case of cancellation in the future.
    var scheduledTask: DispatchWorkItem? { get set }

    /// Schedules a task to be ran after a certain delay. Keeps reference of the `DispatchWorkItem`
    /// so that the work can be cancelled at any time.
    /// - Parameter milliseconds: Delay before running the task in milliseconds.
    /// - Parameter task: A block of code to run after the delay.
    /// - Parameter wallDeadline: Set `true` to use wall time (gettimeofday) instead of absolute time to ensure execution after returning from background
    func scheduleWorkItem(milliseconds: Int, wallDeadline: Bool, closure: @escaping () -> Void)
}

/// Default implementation.
extension TaskSchedulable {
    func scheduleWorkItem(milliseconds: Int, wallDeadline: Bool, closure: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.scheduledTask?.cancel()
            self.scheduledTask = WorkScheduler.scheduleTask(milliseconds: milliseconds,
                                                            closure: closure,
                                                            wallDeadline: wallDeadline)
        }
    }
}

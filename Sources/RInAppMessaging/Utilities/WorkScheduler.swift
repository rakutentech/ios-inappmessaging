import Foundation

/// Struct to help dispatch function calls at a later time in a concurrent queue.
internal struct WorkScheduler {

    static private let inAppMessagingQueue = DispatchQueue(label: "IAM.Worker", attributes: .concurrent)

    /// Function to schedule a function to be invoked at a later time.
    /// - Parameter milliseconds: Milliseconds before invoking the function.
    /// - Parameter closure: Function to be invoked.
    /// - Parameter wallDeadline: Set `true` to use wall time (gettimeofday) instead of absolute time to ensure execution after returning from background
    /// - Returns: A `DispatchWorkItem` object created from passed closure.
    @discardableResult
    static func scheduleTask(milliseconds: Int,
                             closure: @escaping () -> Void,
                             wallDeadline: Bool = false) -> DispatchWorkItem {

        let workItem = DispatchWorkItem { closure() }
        if wallDeadline {
            inAppMessagingQueue.asyncAfter(wallDeadline: .now() + .milliseconds(milliseconds), execute: workItem)
        } else {
            inAppMessagingQueue.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: workItem)
        }
        return workItem
    }
}

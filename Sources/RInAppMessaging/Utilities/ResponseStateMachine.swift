import Foundation

internal struct ResponseStateMachine {
    internal enum State {
        case success
        case error(Error)
    }
    private(set) var previousState = State.success
    private(set) var state = State.success
    private(set) var consecutiveErrorCount = 0

    mutating func push(state: State) {
        previousState = state
        self.state = state
        
        switch state {
        case .success:
            consecutiveErrorCount = 0
        case .error(_):
            consecutiveErrorCount += 1
        }
    }
}

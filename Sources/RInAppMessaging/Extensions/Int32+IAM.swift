import Foundation

extension Int32 {
    /// Exponential backoff
    mutating func increaseBackOff() {
        self = multipliedReportingOverflow(by: 2).partialValue
    }

    /// Exponential backoff with a random value
    ///
    /// - Parameters:
    ///     - min: the minimum value in second.
    ///     - max: the maximum value in second.
    mutating func increaseRandomizedBackoff(min: Int32 = Constants.Retry.Randomized.backOffLowerBoundSeconds,
                                            max: Int32 = Constants.Retry.Randomized.backOffUpperBoundSeconds) {
        increaseBackOff()
        self += Int32.random(in: min...max)*1000
    }
}

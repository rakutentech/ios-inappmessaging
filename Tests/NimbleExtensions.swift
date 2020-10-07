import Nimble

extension Expectation {

    func toAfterTimeout(_ predicate: Predicate<T>,
                        timeout: TimeInterval = 1.0) {

        let timeForExecution: TimeInterval = 1.0
        let totalTimeoutMS = Int((timeout + timeForExecution) * TimeInterval(USEC_PER_SEC))
        waitUntil(timeout: .microseconds(totalTimeoutMS)) { done in
            DispatchQueue.global(qos: .userInteractive).async {
                usleep(useconds_t(timeout * TimeInterval(USEC_PER_SEC)))

                DispatchQueue.main.async {
                    expect {
                        try predicate.satisfies(self.expression)
                    }.toNot(throwError())

                    done()
                }
            }
        }
    }
}

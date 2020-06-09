import Nimble

extension Expectation {

    func toAfterTimeout(_ predicate: Predicate<T>,
                        timeout: TimeInterval = 1.0) {

        let timeForExecution: TimeInterval = 1.0
        waitUntil(timeout: timeout + timeForExecution) { done in
            DispatchQueue.global(qos: .userInteractive).async {
                usleep(useconds_t(timeout * pow(10, 6)))

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

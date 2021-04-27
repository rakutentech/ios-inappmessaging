import Quick
import Nimble
@testable import RInAppMessaging

class AtomicWrapperSpec: QuickSpec {

    @AtomicGetSet var atomicArray = [String]()

    override func spec() {

        struct DelayedValue<T> {
            private let queue = DispatchQueue(label: "DelayedQueue")
            private let delaySeconds = 0.1

            let value: T

            init(_ value: T) {
                self.value = value
            }

            func get() -> T {
                queue.sync {
                    usleep(useconds_t(delaySeconds * Double(USEC_PER_SEC)))
                    return value
                }
            }
        }

        describe("AtomicGetSet property wrapper") {

            let queueA = DispatchQueue(label: "QueueA")
            let queueB = DispatchQueue(label: "QueueB")

            beforeEach {
                self.atomicArray = []
            }

            context("when using mutating functions") {

                // The tests below simulate a situation when one thread tries to modify the value
                // while the other is using mutating function on the same value. The loop was added to ensure effectiveness

                it("should ensure atomicity when using `mutate` functions") {
                    for _ in (1...100) {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        dispatchGroup.enter()

                        queueA.async {
                            let queueDispatchCoordinator = DispatchGroup()
                            queueDispatchCoordinator.enter()
                            queueB.async {
                                queueDispatchCoordinator.wait()
                                self._atomicArray.mutate { $0.append("string 2") }
                                dispatchGroup.leave()
                            }

                            queueDispatchCoordinator.leave()
                            self._atomicArray.mutate { $0.append(DelayedValue("string 1").get()) }
                            dispatchGroup.leave()
                        }
                        dispatchGroup.wait()
                    }

                    let expected = [[String]](repeating: ["string 1", "string 2"], count: 100).flatMap({ $0 })
                    expect(self.atomicArray).to(elementsEqual(expected))
                }

                it("should ensure atomicity when using `mutate` function and setter") {
                    for _ in (1...100) {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        dispatchGroup.enter()

                        queueA.async {
                            let queueDispatchCoordinator = DispatchGroup()
                            queueDispatchCoordinator.enter()
                            queueB.async {
                                queueDispatchCoordinator.wait()
                                self.atomicArray = ["string 2"]
                                dispatchGroup.leave()
                            }

                            queueDispatchCoordinator.leave()
                            self._atomicArray.mutate { $0.append(DelayedValue("string 1").get()) }
                            dispatchGroup.leave()
                        }
                        dispatchGroup.wait()
                        expect(self.atomicArray).to(elementsEqual(["string 2"]))
                    }
                }

                it("should not expect atomic operation without using `mutate` functions") {
                    for _ in (1...100) {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        dispatchGroup.enter()

                        queueA.async {
                            let queueDispatchCoordinator = DispatchGroup()
                            queueDispatchCoordinator.enter()
                            queueB.async {
                                queueDispatchCoordinator.wait()
                                self.atomicArray.append("string 2")
                                dispatchGroup.leave()
                            }

                            queueDispatchCoordinator.leave()
                            self.atomicArray.append(DelayedValue("string 1").get())
                            dispatchGroup.leave()
                        }
                        dispatchGroup.wait()
                    }

                    let expected = [[String]](repeating: ["string 1", "string 2"], count: 100).flatMap({ $0 })
                    expect(self.atomicArray).toNot(elementsEqual(expected))
                }

                it("should not expect atomic operation without using `mutate` function and setter") {
                    for _ in (1...100) {
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                        dispatchGroup.enter()

                        queueA.async {
                            let queueDispatchCoordinator = DispatchGroup()
                            queueDispatchCoordinator.enter()
                            queueB.async {
                                queueDispatchCoordinator.wait()
                                self.atomicArray = ["string 2"]
                                dispatchGroup.leave()
                            }

                            queueDispatchCoordinator.leave()
                            self.atomicArray.append(DelayedValue("string 1").get())
                            dispatchGroup.leave()
                        }
                        dispatchGroup.wait()
                        expect(self.atomicArray).to(elementsEqual(["string 2", "string 1"]))
                    }
                }
            }
        }
    }
}

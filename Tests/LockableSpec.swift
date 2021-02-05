import Quick
import Nimble
@testable import RInAppMessaging

class LockableTestObject: Lockable {
    var resourcesToLock: [LockableResource] {
        return [resource]
    }
    let resource = LockableObject([Int]())

    func append(_ number: Int) {
        var resource = self.resource.get()
        resource.append(number)
        self.resource.set(value: resource)
    }
}

class LockableSpec: QuickSpec {

    override func spec() {

        describe("Lockable object") {
            var lockableObject: LockableTestObject!

            beforeEach {
                lockableObject = LockableTestObject()
                lockableObject.append(1)
                lockableObject.append(2)
            }

            it("will lock provided resources when lock is called on them") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                    lockableObject.append(4)
                })

                lockableObject.resourcesToLock.forEach { $0.lock() }
                expect(lockableObject.resource.get()).toAfterTimeout(equal([1, 2]), timeout: 2.0)
            }

            it("will unlock provided resources when unlock is called on them") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                    lockableObject.append(4)
                })

                lockableObject.resourcesToLock.forEach { $0.lock() }
                sleep(2)
                lockableObject.append(3)
                lockableObject.resourcesToLock.forEach { $0.unlock() }

                expect(lockableObject.resource.get()).toEventually(equal([1, 2, 3, 4]))
            }

            it("will make other threads wait to execute lock() call") {
                let resource = lockableObject.resource
                resource.lock()
                DispatchQueue.global().async {
                    resource.lock()
                    expect(resource.get()).to(equal([1]))
                }
                resource.set(value: [1])
                expect(resource.isLocked).to(beTrue())
                resource.unlock()
                expect(resource.isLocked).toAfterTimeout(beTrue())
            }

            it("will keep the lock if number of unlock() calls did not match the number of lock() calls") {
                let resource = lockableObject.resource
                resource.lock()
                resource.lock()
                expect(resource.isLocked).to(beTrue())
                resource.unlock()
                expect(resource.isLocked).to(beTrue())
            }

            it("will not crash when unlock() was called more times than lock()") {
                let resource = lockableObject.resource
                resource.lock()
                expect(resource.isLocked).to(beTrue())
                resource.unlock()
                resource.unlock()
                expect(resource.isLocked).to(beFalse())
            }

            it("will unlock the thread if the resource was deallocated") {
                var resource: LockableObject? = LockableObject([Int]())
                resource?.lock()
                resource?.lock()
                waitUntil { done in
                    DispatchQueue.global().async {
                        expect(resource?.get()).to(beNil())
                        done()
                    }
                    resource = nil
                }
            }
        }
    }
}

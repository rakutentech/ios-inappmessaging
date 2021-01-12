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
        }
    }
}

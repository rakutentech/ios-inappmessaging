import Quick
import Nimble
@testable import RInAppMessaging

private class LockableTestObject: Lockable {
    var resourcesToLock: [LockableResource] {
        return [resource]
    }
    let resource = LockableObject([1, 2])

    func append(_ number: Int) {
        var resource = self.resource.get()
        resource.append(number)
        self.resource.set(value: resource)
    }
}

class LockableTests: QuickSpec {

    override func spec() {
        describe("CommonUtility.lock") {
            var lockableObject: LockableTestObject!

            beforeEach {
                lockableObject = LockableTestObject()
            }

            it("will lock provided resource for the time of operation") {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                    lockableObject.append(4)
                })
                CommonUtility.lock(resourcesIn: [lockableObject]) {
                    sleep(2)
                    lockableObject.append(3)
                }

                expect(lockableObject.resource.get()).toEventually(equal([1, 2, 3, 4]))
            }
        }
    }
}

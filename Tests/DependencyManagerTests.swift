import Quick
import Nimble
@testable import RInAppMessaging

private protocol SingletonElementType {}
private protocol TransientElementType {}
private class SingletonElement: SingletonElementType {}
private class TransientElement: TransientElementType {}

class DependencyManagerTests: QuickSpec {

    override func spec() {

        context("Dependency Manager") {

            var manager: DependencyManager!
            var container: DependencyManager.Container {
                return DependencyManager.Container([
                    DependencyManager.ContainerElement(type: SingletonElementType.self, factory: { SingletonElement() }),
                    DependencyManager.ContainerElement(type: TransientElementType.self, factory: { TransientElement() }, transient: true)
                ])
            }

            beforeEach {
                manager = DependencyManager()
                manager.appendContainer(container)
            }

            it("will always return the same instance for non-transient element") {
                let instanceOne = manager.resolve(type: SingletonElementType.self)
                let instanceTwo = manager.resolve(type: SingletonElementType.self)

                expect(instanceOne).notTo(beNil())
                expect(instanceOne).to(beIdenticalTo(instanceTwo))
            }

            it("will always return new instance for transient element") {
                let instanceOne = manager.resolve(type: TransientElementType.self)
                let instanceTwo = manager.resolve(type: TransientElementType.self)

                expect(instanceOne).notTo(beNil())
                expect(instanceTwo).notTo(beNil())
                expect(instanceOne).notTo(beIdenticalTo(instanceTwo))
            }

            it("will register using (abstract) type, not factory-used type") {
                let transient = manager.resolve(type: TransientElement.self)
                let singleton = manager.resolve(type: SingletonElement.self)

                expect(transient).to(beNil())
                expect(singleton).to(beNil())
            }

            context("When adding mocks for existing types") {

                class SingletonElementMock: SingletonElementType {}
                class TransientElementMock: TransientElementType {}

                var containerWithMocks: DependencyManager.Container {
                    return DependencyManager.Container([
                        DependencyManager.ContainerElement(type: SingletonElementType.self, factory: { SingletonElementMock() }),
                        DependencyManager.ContainerElement(type: TransientElementType.self, factory: { TransientElementMock() }, transient: true)
                    ])
                }

                beforeEach {
                    manager.appendContainer(containerWithMocks)
                }

                it("will use last registered element (mocked) from container for given type") {
                    let mockedTransient = manager.resolve(type: TransientElementType.self)
                    let mockedSingleton = manager.resolve(type: SingletonElementType.self)

                    expect(mockedTransient).to(beAKindOf(TransientElementMock.self))
                    expect(mockedSingleton).to(beAKindOf(SingletonElementMock.self))
                }
            }
        }
    }
}

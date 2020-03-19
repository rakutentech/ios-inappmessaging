import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior when registering IDs to the SDK.
class IdRegistrationTests: QuickSpec {

    override func spec() {

        func stubContainer() -> DependencyManager.Container {
            return DependencyManager.Container([
                DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                    return ConfigurationManagerStub()
                }),
                DependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: {
                    return MessageMixerServiceMock()
                })
            ])
        }

        let dependencyManager = DependencyManager()
        var preferenceRepository: IAMPreferenceRepository! {
            return dependencyManager.resolve(type: IAMPreferenceRepository.self)
        }

        beforeSuite {
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            dependencyManager.appendContainer(stubContainer())
        }

        beforeEach {
            RInAppMessaging.initializedModule = nil
            RInAppMessaging.configure(dependencyManager: dependencyManager)
        }

        context("ID Registration") {

            it("should not have any matching id type or id value") {
                let expected = [UserIdentifier]()

                expect(expected).toEventually(equal(preferenceRepository.getUserIdentifiers()))
            }

            it("should have one matching id type and id value") {

                RInAppMessaging.registerPreference(
                    IAMPreferenceBuilder()
                        .setUserId("whales and dolphins")
                        .build()
                )

                let expected = [UserIdentifier(type: 3, identifier: "whales and dolphins")]
                expect(preferenceRepository.getUserIdentifiers()).toEventually(equal(expected), timeout: 3, pollInterval: 1)
            }

            it("should have two matching id type and id value") {

                RInAppMessaging.registerPreference(
                    IAMPreferenceBuilder()
                        .setUserId("tigers and zebras")
                        .setRakutenId("whales and dolphins")
                        .build()
                )

                let expected = [UserIdentifier(type: 1, identifier: "whales and dolphins"),
                                UserIdentifier(type: 3, identifier: "tigers and zebras")]
                expect(preferenceRepository.getUserIdentifiers()).toEventually(equal(expected))
            }
        }
    }
}

private class ConfigurationManagerStub: ConfigurationManagerType {
    weak var errorDelegate: ErrorDelegate?
    func fetchAndSaveConfigData(completion: @escaping (ConfigData) -> Void) {
        let emptyURL = URL(string: "about:blank")!
        let emptyEndpoints = EndpointURL(ping: emptyURL,
                                         displayPermission: emptyURL,
                                         impression: emptyURL)
        completion(ConfigData(enabled: true, endpoints: emptyEndpoints))
    }
}

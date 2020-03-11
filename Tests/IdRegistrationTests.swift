import Quick
import Nimble
@testable import RInAppMessaging

/// Tests for behavior when registering IDs to the SDK.
class IdRegistrationTests: QuickSpec {

    override func spec() {

        var preferenceRepository: IAMPreferenceRepository! {
            return RInAppMessaging.dependencyManager?.resolve(type: IAMPreferenceRepository.self)
        }

        func stubContainer() -> DependencyManager.Container {
            return DependencyManager.Container([
                DependencyManager.ContainerElement(type: ConfigurationClient.self, factory: {
                    return ConfigurationClientStub()
                }),
                DependencyManager.ContainerElement(type: MessageMixerClientType.self, factory: {
                    return MessageMixerClientStub()
                })
            ])
        }

        beforeSuite {
            let dependencyManager = DependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            dependencyManager.appendContainer(stubContainer())
            RInAppMessaging.configure(dependencyManager: dependencyManager)
        }

        beforeEach {
            RInAppMessaging.registerPreference(nil)
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
                expect(preferenceRepository.getUserIdentifiers()).toEventually(equal(expected))
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

private class ConfigurationClientStub: ConfigurationClient {
    init() {
        super.init(reachability: nil, configURL: "https://google.com")
    }
    override func isConfigEnabled(retryHandler: @escaping () -> Void) -> Bool {
        return true
    }
}

private class MessageMixerClientStub: MessageMixerClientType {
    weak var errorDelegate: ErrorDelegate?
    func ping() {}
}

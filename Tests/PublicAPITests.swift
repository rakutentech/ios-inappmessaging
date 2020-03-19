import Quick
import Nimble
@testable import RInAppMessaging

class PublicAPITests: QuickSpec {

    override func spec() {

        var eventMatcher: EventMatcherMock!
        var preferenceRepository: IAMPreferenceRepository!
        var router: RouterType!
        var messageMixerService: MessageMixerServiceMock!
        var campaignsListManager: CampaignsListManagerType!

        func mockContainer() -> DependencyManager.Container {
            return DependencyManager.Container([
                DependencyManager.ContainerElement(type: ConfigurationManagerType.self, factory: {
                    let manager = ConfigurationManagerMock()
                    manager.isConfigEnabled = true
                    return manager
                }),
                DependencyManager.ContainerElement(type: MessageMixerServiceType.self, factory: {
                    return messageMixerService
                }),
                DependencyManager.ContainerElement(type: EventMatcherType.self, factory: {
                    return eventMatcher
                })
            ])
        }

        beforeEach {
            RInAppMessaging.initializedModule = nil
            eventMatcher = EventMatcherMock()
            messageMixerService = MessageMixerServiceMock()
            let dependencyManager = DependencyManager()
            dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
            dependencyManager.appendContainer(mockContainer())
            preferenceRepository = dependencyManager.resolve(type: IAMPreferenceRepository.self)!
            router = dependencyManager.resolve(type: RouterType.self)!
            campaignsListManager = dependencyManager.resolve(type: CampaignsListManagerType.self)!
            RInAppMessaging.configure(dependencyManager: dependencyManager)
        }

        describe("RInAppMessaging") {

            it("won't reinitialize module if config was called more than once") {
                // wait for beforeEach configuration to finish
                expect(RInAppMessaging.initializedModule).toEventuallyNot(beNil())

                let expectedModule = RInAppMessaging.initializedModule
                RInAppMessaging.configure()
                expect(RInAppMessaging.initializedModule === expectedModule).toEventuallyNot(beFalse())
            }

            it("will register preference when registerPreference() is called") {
                let preference = IAMPreferenceBuilder()
                    .setUserId("userID")
                    .setRakutenId("RID")
                    .build()
                RInAppMessaging.registerPreference(preference)
                expect(preferenceRepository.preference).toEventually(equal(preference))
            }

            it("will log event when logEvent is called") {
                let event = AppStartEvent()
                RInAppMessaging.logEvent(event)
                expect(eventMatcher.loggedEvents).toEventually(contain(event))
            }

            it("will post notification (RAT) when logEvent is called") {
                expect {
                    RInAppMessaging.logEvent(AppStartEvent())
                }.toEventually(postNotifications(containElementSatisfying({
                    $0.name == Notification.Name("com.rakuten.esd.sdk.events.custom")
                })))
            }

            it("will pass errors to errorDelegate") {
                let delegate = ErrorDelegate()
                RInAppMessaging.errorDelegate = delegate
                messageMixerService.mockedError = .invalidConfiguration
                campaignsListManager.refreshList()
                expect(delegate.returnedError?.domain).toEventually(
                    equal("InAppMessaging.CampaignsListManager"))
                expect(delegate.returnedError?.localizedDescription).toEventually(
                    equal("InAppMessaging: Error retrieving InAppMessaging Mixer Server URL"))
            }

            it("will set accessibilityCompatibleDisplay flag in Router") {
                RInAppMessaging.accessibilityCompatibleDisplay = true
                expect(router.accessibilityCompatibleDisplay).to(beTrue())
                RInAppMessaging.accessibilityCompatibleDisplay = false
                expect(router.accessibilityCompatibleDisplay).to(beFalse())
            }
        }
    }
}

private class ErrorDelegate: RInAppMessagingErrorDelegate {
    private(set) var returnedError: NSError?
    func inAppMessagingDidReturnError(_ error: NSError) {
        returnedError = error
    }
}

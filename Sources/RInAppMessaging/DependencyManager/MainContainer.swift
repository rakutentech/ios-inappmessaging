import Foundation
import UserNotifications

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

/// Collection of methods used to create a container which handles all dependencies in standard SDK usage
internal enum MainContainerFactory {

    private typealias ContainerElement = TypedDependencyManager.ContainerElement

    static func create(dependencyManager manager: TypedDependencyManager, configURL: URL) -> TypedDependencyManager.Container {

        var elements = [
            ContainerElement(type: CommonUtility.self, factory: { CommonUtility() }),
            ContainerElement(type: ReachabilityType.self, factory: {
                Reachability(url: configURL)
            }),
            ContainerElement(type: ConfigurationRepositoryType.self, factory: {
                ConfigurationRepository()
            }),
            ContainerElement(type: ConfigurationManagerType.self, factory: {
                ConfigurationManager(reachability: manager.resolve(type: ReachabilityType.self),
                                     configurationService: manager.resolve(type: ConfigurationServiceType.self),
                                     configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!,
                                     resumeQueue: RInAppMessaging.inAppQueue)
            }),
            ContainerElement(type: UserDataCacheable.self, factory: {
                UserDataCache(userDefaults: UserDefaults.standard,
                              eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: CampaignRepositoryType.self, factory: {
                CampaignRepository(userDataCache: manager.resolve(type: UserDataCacheable.self)!,
                                   accountRepository: manager.resolve(type: AccountRepositoryType.self)!)
            }),
            ContainerElement(type: EventMatcherType.self, factory: {
                EventMatcher(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: AccountRepositoryType.self, factory: {
                AccountRepository(userDataCache: manager.resolve(type: UserDataCacheable.self)!)
            }),
            ContainerElement(type: ConfigurationServiceType.self, factory: {
                ConfigurationService(configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!,
                                     eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: DisplayPermissionServiceType.self, factory: {
                DisplayPermissionService(
                    campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                    accountRepository: manager.resolve(type: AccountRepositoryType.self)!,
                    configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!,
                    eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: RouterType.self, factory: {
                Router(dependencyManager: manager, viewListener: manager.resolve(type: ViewListenerType.self)!)
            }),
            ContainerElement(type: Randomizer.self, factory: {
                Randomizer()
            }),
            ContainerElement(type: CampaignDispatcherType.self, factory: {
                CampaignDispatcher(router: manager.resolve(type: RouterType.self)!,
                                   permissionService: manager.resolve(type: DisplayPermissionServiceType.self)!,
                                   campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                   eventlogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: MessageMixerServiceType.self, factory: {
                MessageMixerService(accountRepository: manager.resolve(type: AccountRepositoryType.self)!,
                                    configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!,
                                    eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: ImpressionServiceType.self, factory: {
                ImpressionService(accountRepository: manager.resolve(type: AccountRepositoryType.self)!,
                                  configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!, eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: CampaignsListManagerType.self, factory: {
                CampaignsListManager(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!,
                                     messageMixerService: manager.resolve(type: MessageMixerServiceType.self)!,
                                     configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!,
                                     eventLogger: manager.resolve(type: EventLoggerSendable.self)!)
            }),
            ContainerElement(type: TooltipDispatcherType.self, factory: {
                TooltipDispatcher(router: manager.resolve(type: RouterType.self)!,
                                  permissionService: manager.resolve(type: DisplayPermissionServiceType.self)!,
                                  campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                  viewListener: manager.resolve(type: ViewListenerType.self)!)
            }),
            ContainerElement(type: TooltipEventSenderType.self, factory: {
                TooltipEventSender(viewListener: manager.resolve(type: ViewListenerType.self)!,
                                   campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: ViewListenerType.self, factory: {
                ViewListener.currentInstance
            }),
            ContainerElement(type: SwiftUIViewEventHandlerType.self, factory: {
                SwiftUIViewEventHandler(router: manager.resolve(type: RouterType.self)!,
                                        dispatcher: manager.resolve(type: TooltipDispatcherType.self)!,
                                        eventSender: manager.resolve(type: TooltipEventSenderType.self)!)
            }),
            ContainerElement(type: EventLoggerSendable.self, factory: {
                EventLogger()
            })
        ]

        // transient containers
        elements.append(contentsOf: [
            ContainerElement(type: CampaignsValidatorType.self, factory: {
                CampaignsValidator(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                   eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                   notificationCenter: UNUserNotificationCenter.current())
            }, transient: true),
            ContainerElement(type: FullViewPresenterType.self, factory: {
                FullViewPresenter(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                  impressionService: manager.resolve(type: ImpressionServiceType.self)!,
                                  eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                  campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!,
                                  pushPrimerOptions: RInAppMessaging.pushPrimerAuthorizationOptions,
                                  configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }, transient: true),
            ContainerElement(type: SlideUpViewPresenterType.self, factory: {
                SlideUpViewPresenter(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     impressionService: manager.resolve(type: ImpressionServiceType.self)!,
                                     eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!,
                                     configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }, transient: true),
            ContainerElement(type: CampaignTriggerAgentType.self, factory: {
                CampaignTriggerAgent(eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     readyCampaignDispatcher: manager.resolve(type: CampaignDispatcherType.self)!,
                                     tooltipDispatcher: manager.resolve(type: TooltipDispatcherType.self)!,
                                     campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!)
            }, transient: true),
            ContainerElement(type: TooltipPresenterType.self, factory: {
                TooltipPresenter(impressionService: manager.resolve(type: ImpressionServiceType.self)!)
            }, transient: true)
        ])

        return TypedDependencyManager.Container(elements)
    }
}

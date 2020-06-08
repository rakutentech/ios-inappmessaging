import Foundation

/// Collection of methods used to create a container which handles all dependencies in standard SDK usage
internal enum MainContainerFactory {

    private typealias ContainerElement = DependencyManager.ContainerElement

    private static var isTestEnvironment: Bool {
        return NSClassFromString("XCTest") != nil
    }

    private static func getValidConfigURL() -> URL? {
        if isTestEnvironment {
            return URL(string: "config.com")
        } else {
            guard let configURLString = BundleInfo.inAppConfigurationURL, !configURLString.isEmpty else {
                return nil
            }
            return URL(string: configURLString)
        }
    }

    static func create(dependencyManager manager: DependencyManager) -> DependencyManager.Container {

        var elements = [
            ContainerElement(type: CommonUtility.self, factory: { CommonUtility() }),
            ContainerElement(type: ReachabilityType.self, factory: {
                guard let configURL = getValidConfigURL() else {
                    assertionFailure("Configuration URL in Info.plist is missing")
                    return nil
                }
                return Reachability(url: configURL)
            }),
            ContainerElement(type: ConfigurationRepositoryType.self, factory: {
                ConfigurationRepository()
            }),
            ContainerElement(type: ConfigurationManagerType.self, factory: {
                ConfigurationManager(reachability: manager.resolve(type: ReachabilityType.self),
                                     configurationService: manager.resolve(type: ConfigurationServiceType.self)!,
                                     configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }),
            ContainerElement(type: CampaignRepositoryType.self, factory: { CampaignRepository() }),
            ContainerElement(type: EventMatcherType.self, factory: {
                EventMatcher(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: IAMPreferenceRepository.self, factory: { IAMPreferenceRepository() }),
            ContainerElement(type: ConfigurationServiceType.self, factory: {
                guard let configURL = getValidConfigURL() else {
                    assertionFailure("Configuration URL in Info.plist is missing")
                    return nil
                }
                let configurationRepository = manager.resolve(type: ConfigurationRepositoryType.self)!
                return ConfigurationService(configURL: configURL,
                                            sessionConfiguration: configurationRepository.defaultHttpSessionConfiguration)
            }),
            ContainerElement(type: DisplayPermissionServiceType.self, factory: {
                DisplayPermissionService(
                    campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                    preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                    configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }),
            ContainerElement(type: RouterType.self, factory: {
                Router(dependencyManager: manager)
            }),
            ContainerElement(type: CampaignDispatcherType.self, factory: {
                CampaignDispatcher(router: manager.resolve(type: RouterType.self)!,
                                        permissionService: manager.resolve(type: DisplayPermissionServiceType.self)!,
                                        campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: MessageMixerServiceType.self, factory: {
                MessageMixerService(preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                                   configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }),
            ContainerElement(type: ImpressionServiceType.self, factory: {
                ImpressionService(preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                                 configurationRepository: manager.resolve(type: ConfigurationRepositoryType.self)!)
            }),
            ContainerElement(type: CampaignsListManagerType.self, factory: {
                CampaignsListManager(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                     campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     readyCampaignDispatcher: manager.resolve(type: CampaignDispatcherType.self)!,
                                     campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!,
                                     messageMixerService: manager.resolve(type: MessageMixerServiceType.self)!)
            })]

        // transient containers
        elements.append(contentsOf: [
            ContainerElement(type: CampaignsValidatorType.self, factory: {
                CampaignsValidator(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                   eventMatcher: manager.resolve(type: EventMatcherType.self)!)
            }, transient: true),
            ContainerElement(type: FullViewPresenterType.self, factory: {
                FullViewPresenter(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                  campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                  impressionService: manager.resolve(type: ImpressionServiceType.self)!,
                                  eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                  campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!)
            }, transient: true),
            ContainerElement(type: SlideUpViewPresenterType.self, factory: {
                SlideUpViewPresenter(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                     campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     impressionService: manager.resolve(type: ImpressionServiceType.self)!,
                                     eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     campaignTriggerAgent: manager.resolve(type: CampaignTriggerAgentType.self)!)
            }, transient: true),
            ContainerElement(type: CampaignTriggerAgentType.self, factory: {
                CampaignTriggerAgent(eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     readyCampaignDispatcher: manager.resolve(type: CampaignDispatcherType.self)!)
            }, transient: true)
        ])

        return DependencyManager.Container(elements)
    }
}

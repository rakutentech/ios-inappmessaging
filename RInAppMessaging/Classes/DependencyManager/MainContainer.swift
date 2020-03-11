import Foundation

/// Collection of methods used to create a container which handles all dependencies in standard SDK usage
internal enum MainContainerFactory {

    private typealias ContainerElement = DependencyManager.ContainerElement

    private static var isTestEnvironment: Bool {
        return NSClassFromString("XCTest") != nil
    }

    private static func getValidConfigURL() -> String? {
        if isTestEnvironment {
            return "config.com"
        } else {
            guard let configURL = Bundle.inAppConfigurationURL, !configURL.isEmpty else {
                return nil
            }
            return configURL
        }
    }

    static func create(dependencyManager manager: DependencyManager) -> DependencyManager.Container {

        return DependencyManager.Container([
            ContainerElement(type: CommonUtility.self, factory: { CommonUtility() }),
            ContainerElement(type: ReachabilityType.self, factory: {
                guard let configURL = getValidConfigURL() else {
                    assertionFailure("Configuration URL in Info.plist is missing")
                    return nil
                }
                return Reachability(url: configURL)
            }),
            ContainerElement(type: ConfigurationClient.self, factory: {
                guard let configURL = getValidConfigURL() else {
                    assertionFailure("Configuration URL in Info.plist is missing")
                    return nil
                }
                return ConfigurationClient(reachability: manager.resolve(type: ReachabilityType.self),
                                           configURL: configURL)
            }),
            ContainerElement(type: CampaignRepositoryType.self, factory: { CampaignRepository() }),
            ContainerElement(type: EventMatcherType.self, factory: {
                EventMatcher(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: IAMPreferenceRepository.self, factory: { IAMPreferenceRepository() }),
            ContainerElement(type: PermissionClientType.self, factory: {
                let configurationClient = manager.resolve(type: ConfigurationClient.self)!
                return PermissionClient(
                    campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                    preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                    pingActionHandler: {
                        let messageMixerClient = manager.resolve(type: MessageMixerClientType.self)!
                        messageMixerClient.ping()
                    },
                    endpointsProvider: configurationClient.getEndpoints)
            }),
            ContainerElement(type: RouterType.self, factory: {
                Router(dependencyManager: manager)
            }),
            ContainerElement(type: ReadyCampaignDispatcherType.self, factory: {
                ReadyCampaignDispatcher(router: manager.resolve(type: RouterType.self)!,
                                        permissionClient: manager.resolve(type: PermissionClientType.self)!,
                                        campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!)
            }),
            ContainerElement(type: MessageMixerClientType.self, factory: {
                let configurationClient = manager.resolve(type: ConfigurationClient.self)!
                return MessageMixerClient(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                          campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                          preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                                          readyCampaignDispatcher: manager.resolve(type: ReadyCampaignDispatcherType.self)!,
                                          eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                          endpointsProvider: configurationClient.getEndpoints)
            }),
            ContainerElement(type: ImpressionClientType.self, factory: {
                let configurationClient = manager.resolve(type: ConfigurationClient.self)!
                return ImpressionClient(preferenceRepository: manager.resolve(type: IAMPreferenceRepository.self)!,
                                        endpointsProvider: configurationClient.getEndpoints)
            }),

            ContainerElement(type: CampaignsValidatorType.self, factory: {
                CampaignsValidator(campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                  eventMatcher: manager.resolve(type: EventMatcherType.self)!)
            }, transient: true),
            ContainerElement(type: FullViewPresenter.self, factory: {
                FullViewPresenter(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                     campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     impressionClient: manager.resolve(type: ImpressionClientType.self)!,
                                     eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     readyCampaignDispatcher: manager.resolve(type: ReadyCampaignDispatcherType.self)!)
            }, transient: true),
            ContainerElement(type: SlideUpViewPresenter.self, factory: {
                SlideUpViewPresenter(campaignsValidator: manager.resolve(type: CampaignsValidatorType.self)!,
                                     campaignRepository: manager.resolve(type: CampaignRepositoryType.self)!,
                                     impressionClient: manager.resolve(type: ImpressionClientType.self)!,
                                     eventMatcher: manager.resolve(type: EventMatcherType.self)!,
                                     readyCampaignDispatcher: manager.resolve(type: ReadyCampaignDispatcherType.self)!)
            }, transient: true)
        ])
    }
}

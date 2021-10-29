import Foundation

internal protocol ConfigurationRepositoryType: AnyObject {
    var defaultHttpSessionConfiguration: URLSessionConfiguration { get }

    func saveConfiguration(_ data: ConfigData)
    func getEndpoints() -> EndpointURL?
    func getRolloutPercentage() -> Int?
}

internal class ConfigurationRepository: ConfigurationRepositoryType {
    private var configuration: ConfigData?
    private(set) var defaultHttpSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        return configuration
    }()

    func saveConfiguration(_ data: ConfigData) {
        configuration = data
    }

    func getEndpoints() -> EndpointURL? {
        configuration?.endpoints
    }

    func getRolloutPercentage() -> Int? {
        configuration?.rolloutPercentage
    }
}

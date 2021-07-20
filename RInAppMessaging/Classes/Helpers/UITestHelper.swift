internal struct UITestHelper {
    static let launchArgument = "--uitesting"
    static let mockedEndpoints = EndpointURL(ping: URL(string: "ui-tests.ping")!,
                                             displayPermission: URL(string: "ui-tests.displayPermission")!,
                                             impression: URL(string: "ui-tests.impressions")!)

    static let mockedGetConfigResponse = GetConfigResponse(data: ConfigData(rolloutPercentage: 100, endpoints: mockedEndpoints))

    static var mockedPingResponse: PingResponse {
        guard let typeArgument = getCampaignTypeLaunchArgument(),
              let jsonURL = Bundle.main.url(forResource: typeArgument, withExtension: "json") else {

            fatalError("unsupported test argument")
        }
        guard let jsonData = try? Data(contentsOf: jsonURL),
              let campaign = try? JSONDecoder().decode(CampaignData.self, from: jsonData) else {
            fatalError("invalid JSON file")
        }

        return PingResponse(nextPingMilliseconds: Int.max, currentPingMilliseconds: 0, data: [Campaign(data: campaign)])
    }

    private static func getCampaignTypeLaunchArgument() -> String? {
        for argument in CommandLine.arguments {
            let keyValue = argument.components(separatedBy: " ")
            if keyValue.count == 2 && keyValue.first == "-campaignType" {
                return keyValue.last
            }
        }
        return nil
    }
}

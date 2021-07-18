internal enum Environment {
    static let isTestEnvironment = Bundle.tests != nil
    static let isUITestEnvironment = CommandLine.arguments.contains(UITestHelper.launchArgument)
}

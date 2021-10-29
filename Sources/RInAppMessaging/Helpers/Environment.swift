import class Foundation.Bundle

internal enum Environment {
    static let isUnitTestEnvironment = Bundle.unitTests != nil
}

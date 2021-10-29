import struct Foundation.Data
import CommonCrypto

/// Tool for creating a salted hash from given string values using selected KeyHasher.Encryption method
internal struct KeyHasher {

    enum Encryption: String {
        case md5
        case sha256
    }

    var encryptionMethod = Encryption.sha256
    var salt: String?

    private var data = [String]()

    mutating func combine(_ value: String) {
        data.append(value)
    }

    mutating func generateHash() -> String {
        var dataString = data.joined(separator: ".")
        if let salt = salt, !salt.isEmpty {
            dataString.append(salt)
        }

        switch encryptionMethod {
        case .sha256:
            return sha256(string: dataString)
        case .md5:
            return md5(string: dataString)
        }
    }

    // MARK: Hashing functions

    private func md5(string: String) -> String {
        let stringData = Data(string.utf8)

        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        stringData.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(stringData.count), &hash)
        }
        return Data(hash).hexString
    }

    private func sha256(string: String) -> String {
        let stringData = Data(string.utf8)

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        stringData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(stringData.count), &hash)
        }
        return Data(hash).hexString
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

import Foundation
import Security

struct AutoFillToken: Codable {
  let uid: String
  let issuer: String
  let account: String
  let secret: String
  let algorithm: String
  let digits: Int
  let period: Int
  let domain: String?
  var label: String { [issuer, account].filter { !$0.isEmpty }.joined(separator: " · ") }
}

enum AutoFillVault {
  private static func query() throws -> [String: Any] {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "CloudOTPKeychainGroup") as? String,
          !group.isEmpty, !group.contains("$(") else {
      throw NSError(domain: "CloudOTP.AutoFill", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "AutoFill signing is not configured."])
    }
    return [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "CloudOTP.AutoFill.v1",
            kSecAttrAccount as String: "tokens",
            kSecAttrAccessGroup as String: group]
  }
  static func save(_ data: Data) throws {
    let query = try query()
    var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      status = SecItemAdd(item as CFDictionary, nil)
    }
    guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
  }
  static func clear() throws {
    let status = SecItemDelete(try query() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }
  // Only the credential extension reads this after a fresh device-owner check.
  static func load() throws -> [AutoFillToken] {
    var query = try query()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var value: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &value)
    if status == errSecItemNotFound { return [] }
    guard status == errSecSuccess, let data = value as? Data else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    return try JSONDecoder().decode([AutoFillToken].self, from: data)
  }
}

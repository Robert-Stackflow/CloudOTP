import Foundation
import CryptoKit

enum OTPGenerator {
  static func code(secret: String, algorithm: String, digits: Int, period: Int, time: TimeInterval = Date().timeIntervalSince1970) -> String? {
    guard (6...10).contains(digits), period > 0, time >= 0, time.isFinite,
          time / Double(period) < Double(UInt64.max), let key = decodeBase32(secret) else { return nil }
    var counter = UInt64(time / Double(period)).bigEndian
    let message = withUnsafeBytes(of: &counter) { Data($0) }
    let symmetricKey = SymmetricKey(data: key)
    let hash: [UInt8]
    switch algorithm.uppercased().replacingOccurrences(of: "-", with: "") {
    case "SHA1": hash = Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: symmetricKey))
    case "SHA256": hash = Array(HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey))
    case "SHA512": hash = Array(HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey))
    default: return nil
    }
    let offset = Int(hash[hash.count - 1] & 0x0f)
    let binary = (UInt64(hash[offset] & 0x7f) << 24) | (UInt64(hash[offset + 1]) << 16) |
                 (UInt64(hash[offset + 2]) << 8) | UInt64(hash[offset + 3])
    let modulus = (0..<digits).reduce(UInt64(1)) { value, _ in value * 10 }
    let value = String(binary % modulus)
    return String(repeating: "0", count: digits - value.count) + value
  }
  static func decodeBase32(_ value: String) -> Data? {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    let cleaned = value.uppercased().filter { !$0.isWhitespace }
    let parts = cleaned.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
    guard let body = parts.first, !body.isEmpty,
          parts.count == 1 || parts[1].allSatisfy({ $0 == "=" }) else { return nil }
    var accumulator: UInt32 = 0
    var bits = 0
    var bytes: [UInt8] = []
    for character in body {
      guard let index = alphabet.firstIndex(of: character) else { return nil }
      accumulator = (accumulator << 5) | UInt32(index)
      bits += 5
      if bits >= 8 {
        bits -= 8
        bytes.append(UInt8((accumulator >> bits) & 0xff))
      }
      accumulator &= bits == 0 ? 0 : (1 << bits) - 1
    }
    guard !bytes.isEmpty, accumulator == 0 else { return nil }
    return Data(bytes)
  }
}

import Foundation
@main struct Vectors {
  static func main() {
    let sha1 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
    let sha256 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA===="
    let sha512 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNA="
    let times: [TimeInterval] = [59,1111111109,1111111111,1234567890,2000000000,20000000000]
    let expected = [
      ["94287082","07081804","14050471","89005924","69279037","65353130"],
      ["46119246","68084774","67062674","91819424","90698825","77737706"],
      ["90693936","25091201","99943326","93441116","38618901","47863826"]]
    for (a, algorithm) in ["SHA1","SHA256","SHA512"].enumerated() {
      for (i,time) in times.enumerated() {
        let value = OTPGenerator.code(secret: [sha1,sha256,sha512][a], algorithm: algorithm, digits: 8, period: 30, time: time)
        precondition(value == expected[a][i], "RFC6238 \(algorithm) at \(time): \(String(describing:value))")
      }
    }
    precondition(OTPGenerator.code(secret: sha1, algorithm: "SHA1", digits: 6, period: 30, time: 59) == "287082")
    precondition(OTPGenerator.code(secret: "NOT!VALID", algorithm: "SHA1", digits: 6, period: 30) == nil)
    precondition(OTPGenerator.code(secret: sha1, algorithm: "SHA1", digits: 6, period: 0) == nil)
    precondition(OTPGenerator.code(secret: sha1, algorithm: "MD5", digits: 6, period: 30) == nil)
    print("22 OTP vector and validation checks passed")
  }
}

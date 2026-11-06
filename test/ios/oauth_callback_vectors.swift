import Foundation

@main
struct CallbackTests {
    static func main() {
        let authorization = URL(string: "https://example.com/authorize?state=expected")!
        let expected = URL(string: "cloudotp://auth/googledrive/callback")!
        let callback = OAuthCallback(url: expected, authorizationURL: authorization)!
        let valid = URL(string: "cloudotp://auth/googledrive/callback?code=test&state=expected")!
        precondition(callback.matchesEndpoint(valid) && callback.hasValidState(valid))
        for text in [
            "other://auth/googledrive/callback?state=expected",
            "cloudotp://auth/dropbox/callback?state=expected",
            "cloudotp://other/googledrive/callback?state=expected",
            "cloudotp://user@auth/googledrive/callback?state=expected",
            "cloudotp://auth:123/googledrive/callback?state=expected",
            "cloudotp://auth/googledrive/callback?state=expected#fragment",
        ] { precondition(!callback.matchesEndpoint(URL(string: text)!)) }
        for query in ["state=wrong", "state=expected&state=expected", "code=test", "state="] {
            precondition(!callback.hasValidState(URL(string: expected.absoluteString + "?" + query)!))
        }
        precondition(OAuthCallback(url: expected, authorizationURL: URL(string: "https://example.com?state=a&state=b")!) == nil)
        precondition(OAuthCallback(url: URL(string: "http://example.com/callback")!, authorizationURL: authorization) == nil)
        print("OAuth native callback: 13 checks passed")
    }
}

import Foundation

/// Exact redirect identity and state; shared by system and scene callbacks.
struct OAuthCallback {
    let url: URL
    let scheme: String
    let state: String

    init?(url: URL, authorizationURL: URL) {
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty,
              scheme != "http", url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil,
              let items = URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }
        let states = items.filter { $0.name == "state" }
        guard states.count == 1, let state = states.first?.value, !state.isEmpty,
              scheme != "https" || !(url.host ?? "").isEmpty
        else { return nil }
        self.url = url
        self.scheme = scheme
        self.state = state
    }

    func matchesEndpoint(_ candidate: URL) -> Bool {
        guard let expected = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let received = URLComponents(url: candidate, resolvingAgainstBaseURL: false)
        else { return false }
        return received.scheme?.lowercased() == scheme &&
            received.host?.lowercased() == expected.host?.lowercased() &&
            received.port == expected.port &&
            received.percentEncodedPath == expected.percentEncodedPath &&
            received.user == nil && received.password == nil && received.fragment == nil
    }

    func hasValidState(_ candidate: URL) -> Bool {
        let states = URLComponents(url: candidate, resolvingAgainstBaseURL: false)?
            .queryItems?.filter { $0.name == "state" } ?? []
        return states.count == 1 && states.first?.value == state
    }
}

import Foundation

@main
struct PrivacyTests {
    static func main() {
        var policy = PrivacyCoverPolicy()
        let now = Date(timeIntervalSince1970: 1_000)
        policy.deactivate(now: now)
        precondition(!policy.shouldCover)
        policy.enabled = true
        precondition(policy.shouldCover) // app-switcher, before background
        policy.activate()
        precondition(!policy.shouldCover)
        let faceID = policy.beginAuthentication(now: now)
        policy.deactivate(now: now)
        precondition(!policy.shouldCover) // no grey screen during our Face ID
        policy.endAuthentication(faceID)
        policy.deactivate(now: now) // duplicate application/scene notifications
        precondition(!policy.shouldCover) // nor at authentication completion
        policy.enterBackground()
        precondition(policy.shouldCover) // privacy always wins in real background
        policy.activate()
        precondition(!policy.shouldCover)
        policy.deactivate(now: now)
        precondition(policy.shouldCover) // next normal switch is protected
        policy.activate()
        let keychain = policy.beginAuthentication(now: now)
        let overlapping = policy.beginAuthentication(now: now)
        policy.endAuthentication(keychain)
        policy.deactivate(now: now)
        precondition(!policy.shouldCover)
        policy.endAuthentication(overlapping)
        policy.enterBackground()
        precondition(policy.shouldCover)
        policy.activate()
        _ = policy.beginAuthentication(now: now)
        policy.deactivate(now: now.addingTimeInterval(121))
        precondition(policy.shouldCover) // abandoned lease expires
        policy.enabled = false
        precondition(!policy.shouldCover)
        print("Privacy cover policy: 12 checks passed")
    }
}

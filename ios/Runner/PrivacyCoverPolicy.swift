import Foundation

/// Deactivation includes both app switching and system authentication. Only the
/// latter may keep the foreground visible; true backgrounding is always covered.
struct PrivacyCoverPolicy {
    enum Phase { case active, inactive, background }
    var enabled = false
    private(set) var phase: Phase = .active
    private var authenticationLeases: [UUID: Date] = [:]
    private var inactiveForAuthentication = false

    var shouldCover: Bool {
        enabled && (phase == .background || (phase == .inactive && !inactiveForAuthentication))
    }

    mutating func beginAuthentication(now: Date = Date()) -> UUID {
        let id = UUID()
        authenticationLeases[id] = now.addingTimeInterval(120)
        return id
    }

    mutating func endAuthentication(_ id: UUID) {
        authenticationLeases.removeValue(forKey: id)
        // Completion can precede didActivate. Preserve the classification of
        // this inactive transition to avoid a grey frame after Face ID ends.
    }

    mutating func deactivate(now: Date = Date()) {
        guard phase == .active else { return } // scene + application duplicates
        authenticationLeases = authenticationLeases.filter { $0.value > now }
        inactiveForAuthentication = !authenticationLeases.isEmpty
        phase = .inactive
    }

    mutating func enterBackground() { phase = .background }
    mutating func activate() { phase = .active; inactiveForAuthentication = false }
}

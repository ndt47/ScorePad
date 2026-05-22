import Foundation

/// Minimal interface a game-session model must satisfy to work with GameSessionList.
protocol GameSession {
    /// A stable string identifier used for List selection binding.
    var sessionID: String { get }
    var isFinished: Bool { get }
    var dateCreated: Date { get }
}

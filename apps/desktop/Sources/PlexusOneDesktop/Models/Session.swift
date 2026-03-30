import Foundation
import AssistantKit

/// Represents a tmux session that can be attached to a pane
struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let tmuxSession: String
    var agentType: AgentType?
    var status: SessionStatus
    var lastActivity: Date
    var metadata: [String: String]
    var inputStatus: InputStatus?

    init(
        id: UUID = UUID(),
        name: String,
        tmuxSession: String? = nil,
        agentType: AgentType? = nil,
        status: SessionStatus = .detached,
        lastActivity: Date = Date(),
        metadata: [String: String] = [:],
        inputStatus: InputStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.tmuxSession = tmuxSession ?? name
        self.agentType = agentType
        self.status = status
        self.lastActivity = lastActivity
        self.metadata = metadata
        self.inputStatus = inputStatus
    }
}

/// Status of detected input prompt
struct InputStatus: Codable, Hashable {
    let detectedAt: Date
    let patternType: String  // PatternType.rawValue
    let matchedText: String
    let confidence: Double

    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(detectedAt)
        hasher.combine(patternType)
        hasher.combine(matchedText)
    }

    static func == (lhs: InputStatus, rhs: InputStatus) -> Bool {
        lhs.detectedAt == rhs.detectedAt &&
        lhs.patternType == rhs.patternType &&
        lhs.matchedText == rhs.matchedText
    }
}

/// Status of a tmux session based on activity
enum SessionStatus: String, Codable, Hashable {
    case running    // Active output within threshold
    case idle       // No recent output
    case stuck      // No output for extended period
    case detached   // No pane attached (still running in tmux)

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .idle: return "Idle"
        case .stuck: return "Stuck"
        case .detached: return "Detached"
        }
    }

    var statusColor: String {
        switch self {
        case .running: return "green"
        case .idle: return "yellow"
        case .stuck: return "red"
        case .detached: return "gray"
        }
    }
}

/// Type of AI agent running in the session
enum AgentType: String, Codable, Hashable, CaseIterable {
    case claude
    case codex
    case gemini
    case kiro
    case custom

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .gemini: return "Gemini"
        case .kiro: return "Kiro"
        case .custom: return "Custom"
        }
    }
}

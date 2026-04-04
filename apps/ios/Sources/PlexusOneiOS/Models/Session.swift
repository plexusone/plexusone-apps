import Foundation

/// Represents a tmux session
struct Session: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let status: SessionStatus
    let createdAt: Date?

    enum SessionStatus: String, Codable {
        case running
        case idle
        case stuck
        case error
        case unknown
    }

    init(id: String, name: String, status: SessionStatus = .unknown, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        let statusString = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        status = SessionStatus(rawValue: statusString) ?? .unknown

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
}

/// Message types for WebSocket communication
enum WSMessageType: String, Codable {
    case sessions
    case output
    case prompt
    case menu
    case status
    case error
}

/// WebSocket message wrapper
struct WSMessage: Codable {
    let type: WSMessageType
    let sessionId: String?
    let data: AnyCodable?
}

/// Type-erased Codable wrapper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    /// Get value as string
    var stringValue: String? {
        value as? String
    }

    /// Get value as array of dictionaries
    var arrayValue: [[String: Any]]? {
        value as? [[String: Any]]
    }

    /// Get value as dictionary
    var dictValue: [String: Any]? {
        value as? [String: Any]
    }
}

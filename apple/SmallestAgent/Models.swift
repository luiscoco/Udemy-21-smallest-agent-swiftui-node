import Foundation

struct Health: Decodable { let status: String; let apiKeyConfigured: Bool }
struct AgentResult: Codable {
    let result: String
    let numTurns: Int
    let durationMs: Double
    let totalCostUsd: Double?
    let isError: Bool
    var isValid: Bool { numTurns >= 0 && durationMs.isFinite && durationMs >= 0 && (totalCostUsd == nil || totalCostUsd!.isFinite) }
}
enum JSONValue: Codable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Double), bool(Bool), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else { self = .array(try c.decode([JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v); case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v); case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v); case .null: try c.encodeNil()
        }
    }
    subscript(key: String) -> JSONValue? { if case .object(let value) = self { return value[key] }; return nil }
    var text: String? { if case .string(let value) = self { return value }; return nil }
    var pretty: String { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; return String(data: (try? e.encode(self)) ?? Data(), encoding: .utf8) ?? "{}" }
}
struct AgentMessage: Decodable, Identifiable {
    var id = UUID()
    let type: String
    let summary: String
    let data: JSONValue
    enum CodingKeys: String, CodingKey { case type, summary, data }
    var finalResult: AgentResult? {
        guard type == "ResultMessage", let bytes = try? JSONEncoder().encode(data),
              let value = try? APIClient.decoder().decode(AgentResult.self, from: bytes), value.isValid else { return nil }
        return value
    }
}
struct TimelineEntry: Identifiable { let id = UUID(); let message: AgentMessage; let elapsed: Int }
enum APIError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let value) = self { return value }; return nil }
}
struct WorkflowStep: Decodable, Identifiable {
    let number: Int; let from: Int; let to: Int; let title: String; let source: String; let line: Int
    let language: String; let text: String; let explanation: String; let code: String
    var id: Int { number }
}
enum Resources {
    static func url(_ name: String, _ ext: String) -> URL? { Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") }
    static let steps: [WorkflowStep] = {
        guard let resourceURL = Resources.url("workflow", "json"), let data = try? Data(contentsOf: resourceURL), let value = try? JSONDecoder().decode([WorkflowStep].self, from: data) else { return [] }
        return value
    }()
}

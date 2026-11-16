import Foundation

struct SSEEvent { let name: String; let data: Data }
struct SSEParser {
    private var line = Data()
    private var event = "message"
    private var rows: [String] = []
    private var frameBytes = 0
    mutating func append(_ byte: UInt8) throws -> SSEEvent? {
        frameBytes += 1
        guard frameBytes <= 1_048_576 else { throw APIError.message("The stream frame is too large.") }
        if byte != 10 { line.append(byte); return nil }
        if line.last == 13 { line.removeLast() }
        guard let value = String(data: line, encoding: .utf8) else { throw APIError.message("The stream contains invalid UTF-8.") }
        line.removeAll(keepingCapacity: true)
        if value.isEmpty {
            let result = rows.isEmpty ? nil : SSEEvent(name: event, data: Data(rows.joined(separator: "\n").utf8))
            rows.removeAll(keepingCapacity: true); event = "message"; frameBytes = 0
            return result
        }
        if value.hasPrefix(":") { return nil }
        let fields = value.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let key = String(fields[0]); var content = fields.count > 1 ? String(fields[1]) : ""
        if content.hasPrefix(" ") { content.removeFirst() }
        if key == "event" { event = content }; if key == "data" { rows.append(content) }
        return nil
    }
    func finish() throws {
        guard line.isEmpty && rows.isEmpty && event == "message" else { throw APIError.message("The stream ended inside an event. Please try again.") }
    }
}

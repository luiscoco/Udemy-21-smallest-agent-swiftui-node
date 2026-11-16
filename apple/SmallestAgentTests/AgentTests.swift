import XCTest
@testable import SmallestAgent

final class AgentTests: XCTestCase {
    private func parse(_ text: String) throws -> [SSEEvent] {
        var parser = SSEParser(); var events: [SSEEvent] = []
        for byte in text.utf8 { if let value = try parser.append(byte) { events.append(value) } }
        try parser.finish(); return events
    }
    func testFragmentedUnicodeAndCRLF() throws {
        let events = try parse(": heartbeat\r\n\r\nevent: message\r\ndata: {\"text\":\"Hello 🌍 café\"}\r\n\r\n")
        XCTAssertEqual(events.count, 1); XCTAssertEqual(events[0].name, "message")
        XCTAssertEqual(String(data: events[0].data, encoding: .utf8), "{\"text\":\"Hello 🌍 café\"}")
    }
    func testMultilineDataAndDone() throws {
        let events = try parse("event: message\ndata: {\ndata: \"type\":\"OtherMessage\"\ndata: }\n\nevent: done\ndata: {}\n\n")
        XCTAssertEqual(events.count, 2); XCTAssertEqual(events[1].name, "done")
        XCTAssertNotNil(try JSONSerialization.jsonObject(with: events[0].data))
    }
    func testTruncatedFrameFails() throws {
        var parser = SSEParser(); for byte in "event: message\ndata: {}".utf8 { _ = try parser.append(byte) }
        XCTAssertThrowsError(try parser.finish())
    }
    func testOversizedFrameFails() throws {
        var parser = SSEParser()
        XCTAssertThrowsError(try (0...1_048_576).forEach { _ in _ = try parser.append(65) })
    }
    func testInvalidUTF8Fails() throws {
        var parser = SSEParser(); _ = try parser.append(255)
        XCTAssertThrowsError(try parser.append(10))
    }
    func testValidatesServerOrigin() throws {
        XCTAssertNoThrow(try APIClient.validatedURL("https://agent.example.com"))
        for url in ["file:///tmp/key", "javascript:alert(1)", "https://user:secret@example.com", "https://example.com/api", "https://example.com?key=secret"] {
            XCTAssertThrowsError(try APIClient.validatedURL(url))
        }
    }
    func testPreservesResultErrorAndUnknownCost() throws {
        let bytes = Data(#"{"type":"ResultMessage","summary":"failed","data":{"result":"partial","num_turns":1,"duration_ms":20,"total_cost_usd":null,"is_error":true}}"#.utf8)
        let message = try JSONDecoder().decode(AgentMessage.self, from: bytes)
        let result = try XCTUnwrap(message.finalResult); XCTAssertTrue(result.isError); XCTAssertNil(result.totalCostUsd)
    }
    func testRejectsMalformedFinalResult() throws {
        let message = try JSONDecoder().decode(AgentMessage.self, from: Data(#"{"type":"ResultMessage","summary":"bad","data":{"result":42}}"#.utf8))
        XCTAssertNil(message.finalResult)
    }
    func testWorkflowHasEveryNumberAndSource() {
        XCTAssertEqual(Resources.steps.map(\.number), Array(1...16))
        XCTAssertTrue(Resources.steps.allSatisfy { !$0.source.isEmpty && $0.line > 0 && !$0.code.isEmpty })
    }
}

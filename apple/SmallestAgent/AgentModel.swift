import SwiftUI

@MainActor final class AgentModel: ObservableObject {
    @Published var prompt = "Hello world!"
    @Published var streaming = true
    @Published var running = false
    @Published var phase = "idle"
    @Published var result: AgentResult?
    @Published var partial = ""
    @Published var messages: [TimelineEntry] = []
    @Published var health: Health?
    @Published var notice = ""
    @Published var elapsed = 0
    private var task: Task<Void, Never>?
    private var timer: Task<Void, Never>?
    private var started = Date()
    func checkHealth(_ base: String) async {
        health = nil
        do { let client = APIClient(baseURL: try APIClient.validatedURL(base)); health = try await client.health() }
        catch { if !Task.isCancelled { notice = "Backend unavailable. Check the server address and start Node." } }
    }
    func run(_ base: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !running, !trimmed.isEmpty, trimmed.utf16.count <= 4000 else { return }
        running = true; phase = "running"; result = nil; partial = ""; messages = []; notice = ""; elapsed = 0; started = Date()
        let mode = streaming
        timer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, let self = self else { return }; self.elapsed = Int(Date().timeIntervalSince(self.started) * 1000)
            }
        }
        task = Task { [weak self] in
            guard let self = self else { return }
            defer { self.timer?.cancel(); self.running = false; self.elapsed = Int(Date().timeIntervalSince(self.started) * 1000) }
            do {
                let client = APIClient(baseURL: try APIClient.validatedURL(base))
                if mode {
                    try await client.stream(trimmed) { message in
                        if message.type == "AssistantMessage", let text = message.data["text"]?.text { self.partial = text }
                        if self.messages.count < 500 { self.messages.append(TimelineEntry(message: message, elapsed: Int(Date().timeIntervalSince(self.started) * 1000))) }
                        // Final processing stays outside the display-history cap.
                        if let result = message.finalResult { self.result = result }
                    }
                } else { self.result = try await client.query(trimmed) }
                guard let result = self.result else { throw APIError.message("The agent returned no final result.") }
                if result.isError { throw APIError.message("The agent could not complete this prompt. Check server configuration and try again.") }
                self.phase = "success"
            } catch {
                if Task.isCancelled { self.phase = "cancelled"; self.notice = "Request cancelled." }
                else { self.phase = "error"; self.notice = error.localizedDescription }
            }
        }
    }
    func cancel() { task?.cancel() }
}

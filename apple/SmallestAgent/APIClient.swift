import Foundation

struct APIClient {
    let baseURL: URL
    static func decoder() -> JSONDecoder { let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase; return decoder }
    static func validatedURL(_ text: String) throws -> URL {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else { throw APIError.message("Enter a server origin such as https://agent.example.com, without a path or credentials.") }
        #if !DEBUG
        guard url.scheme?.lowercased() == "https" else { throw APIError.message("Release builds require an HTTPS server.") }
        #endif
        return url
    }
    private func request(_ path: String, prompt: String? = nil) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url); request.timeoutInterval = 190
        if let prompt = prompt { request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try JSONEncoder().encode(["prompt": prompt]) }
        return request
    }
    private func makeSession() -> URLSession {
        let c = URLSessionConfiguration.ephemeral; c.timeoutIntervalForRequest = 190; c.timeoutIntervalForResource = 195
        return URLSession(configuration: c)
    }
    private func read(_ request: URLRequest) async throws -> Data {
        let session = makeSession(); defer { session.invalidateAndCancel() }
        return try await withTaskCancellationHandler(operation: {
            let (bytes, response) = try await session.bytes(for: request)
            var data = Data()
            for try await byte in bytes { try Task.checkCancellation(); guard data.count < 1_048_576 else { throw APIError.message("The response is too large.") }; data.append(byte) }
            try check(response, data: data); return data
        }, onCancel: { session.invalidateAndCancel() })
    }
    private func check(_ response: URLResponse, data: Data = Data()) throws {
        guard let response = response as? HTTPURLResponse else { throw APIError.message("The server returned an invalid response.") }
        guard (200...299).contains(response.statusCode) else {
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
            throw APIError.message(detail ?? "Server returned HTTP \(response.statusCode). Check its address and configuration.")
        }
    }
    func health() async throws -> Health { try Self.decoder().decode(Health.self, from: await read(request("api/health"))) }
    func query(_ prompt: String) async throws -> AgentResult {
        let value = try Self.decoder().decode(AgentResult.self, from: await read(request("api/agent/query", prompt: prompt)))
        guard value.isValid else { throw APIError.message("The server returned an invalid final result.") }; return value
    }
    func stream(_ prompt: String, onMessage: @escaping @MainActor (AgentMessage) -> Void) async throws {
        let session = makeSession(); defer { session.invalidateAndCancel() }
        try await withTaskCancellationHandler(operation: {
            let (bytes, response) = try await session.bytes(for: request("api/agent/stream", prompt: prompt))
            guard let http = response as? HTTPURLResponse else { throw APIError.message("Invalid server response.") }
            if !(200...299).contains(http.statusCode) {
                var error = Data(); for try await byte in bytes { guard error.count < 65536 else { break }; error.append(byte) }
                try check(response, data: error)
            }
            guard http.value(forHTTPHeaderField: "Content-Type")?.lowercased().hasPrefix("text/event-stream") == true else { throw APIError.message("The server did not return an event stream.") }
            var parser = SSEParser(); var resultSeen = false; var doneSeen = false
            for try await byte in bytes {
                try Task.checkCancellation()
                guard let event = try parser.append(byte) else { continue }
                if event.name == "error" {
                    let detail = (try? JSONDecoder().decode([String: String].self, from: event.data))?["detail"]
                    throw APIError.message(detail ?? "The agent could not finish. Check server configuration.")
                }
                if event.name == "message" {
                    let message = try JSONDecoder().decode(AgentMessage.self, from: event.data)
                    if message.type == "ResultMessage" {
                        guard message.finalResult != nil else { throw APIError.message("The final result is malformed.") }
                        resultSeen = true
                    }
                    await onMessage(message)
                }
                if event.name == "done" { guard resultSeen else { throw APIError.message("The stream completed without a final result.") }; doneSeen = true; break }
            }
            try parser.finish()
            guard resultSeen && doneSeen else { throw APIError.message("The stream ended before completion. Please try again.") }
        }, onCancel: { session.invalidateAndCancel() })
    }
}

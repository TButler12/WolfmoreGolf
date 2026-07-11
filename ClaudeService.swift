import Foundation

enum ClaudeService {

    static func generate(systemPrompt: String, userMessage: String) async throws -> String {
        let edgeFunctionURL = SUPABASE_URL.appendingPathComponent("functions/v1/generate-round-summary")

        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue(SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SUPABASE_ANON_KEY)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "context":      userMessage,
            "systemPrompt": systemPrompt,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let raw = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw Err.edgeFunction(raw)
        }

        struct Resp: Decodable {
            let summary: String?
            let error: String?
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)

        if let errMsg = decoded.error {
            throw Err.edgeFunction(errMsg)
        }
        guard let text = decoded.summary, !text.isEmpty else {
            throw Err.empty
        }
        return text
    }

    enum Err: LocalizedError {
        case empty, edgeFunction(String)
        var errorDescription: String? {
            switch self {
            case .empty:               return "The summary came back empty. Try again."
            case .edgeFunction(let m): return m
            }
        }
    }
}

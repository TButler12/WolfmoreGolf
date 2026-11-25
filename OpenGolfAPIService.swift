import Foundation

// MARK: - Wire models (field names match actual API responses, not the OpenAPI spec)

struct OpenGolfSearchResult: Decodable {
    let id: Int
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let par: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, city, state, country, par
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try  c.decode(Int.self,    forKey: .id)
        name    = try  c.decode(String.self, forKey: .name)
        city    = try? c.decode(String.self, forKey: .city)
        state   = try? c.decode(String.self, forKey: .state)
        country = try? c.decode(String.self, forKey: .country)
        par     = try? c.decode(Int.self,    forKey: .par)
    }

    var locationLabel: String {
        [city, state].compactMap { $0 }.joined(separator: ", ")
    }
}

struct OpenGolfHoleData: Decodable {
    let holeNumber: Int
    let par: Int
    let handicapIndex: Int?

    enum CodingKeys: String, CodingKey {
        case holeNumber   = "hole_number"
        case par
        case handicapIndex = "handicap_index"
    }

    init(from decoder: Decoder) throws {
        let c         = try decoder.container(keyedBy: CodingKeys.self)
        holeNumber    = try  c.decode(Int.self, forKey: .holeNumber)
        par           = try  c.decode(Int.self, forKey: .par)
        handicapIndex = try? c.decode(Int.self, forKey: .handicapIndex)
    }
}

// MARK: - Service

final class OpenGolfAPIService {
    static let shared = OpenGolfAPIService()
    private init() {}

    private let base = URL(string: "https://api.opengolfapi.org")!
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    func search(query: String) async throws -> [OpenGolfSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var comps = URLComponents(url: base.appendingPathComponent("api/v1/courses/search"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        let (data, response) = try await session.data(from: comps.url!)
        try checkHTTP(response)

        // Response is either a top-level array or {"results": [...]}
        if let arr = try? JSONDecoder().decode([OpenGolfSearchResult].self, from: data) {
            return arr
        }
        struct Wrapper: Decodable { let results: [OpenGolfSearchResult] }
        return try JSONDecoder().decode(Wrapper.self, from: data).results
    }

    func holes(courseId: Int) async throws -> [OpenGolfHoleData] {
        let url = base.appendingPathComponent("api/v1/courses/\(courseId)/holes")
        let (data, response) = try await session.data(from: url)
        try checkHTTP(response)
        if let arr = try? JSONDecoder().decode([OpenGolfHoleData].self, from: data) {
            return arr.sorted { $0.holeNumber < $1.holeNumber }
        }
        struct Wrapper: Decodable { let holes: [OpenGolfHoleData] }
        let wrapped = try JSONDecoder().decode(Wrapper.self, from: data)
        return wrapped.holes.sorted { $0.holeNumber < $1.holeNumber }
    }

    private func checkHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

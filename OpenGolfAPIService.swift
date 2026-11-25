import Foundation

// MARK: - Wire models (field names match actual API responses)

struct OpenGolfSearchResult: Decodable {
    let id: String
    let name: String
    let city: String?
    let state: String?
    let country: String?
    let par: Int?
    let phone: String?
    let website: String?

    enum CodingKeys: String, CodingKey {
        case id, name, city, state, country, par, phone, website
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try  c.decode(String.self, forKey: .id)
        name    = try  c.decode(String.self, forKey: .name)
        city    = try? c.decode(String.self, forKey: .city)
        state   = try? c.decode(String.self, forKey: .state)
        country = try? c.decode(String.self, forKey: .country)
        par     = try? c.decode(Int.self,    forKey: .par)
        phone   = try? c.decode(String.self, forKey: .phone)
        website = try? c.decode(String.self, forKey: .website)
    }

    var locationLabel: String {
        [city, state].compactMap { $0 }.joined(separator: ", ")
    }
}

// Fields from /api/v1/courses/{id} → holes_data[].
// Keys: number, par, handicap_index (extra fields in the response are ignored).
struct OpenGolfHoleData: Decodable {
    let holeNumber: Int
    let par: Int
    let handicapIndex: Int?

    enum CodingKeys: String, CodingKey {
        case holeNumber    = "number"
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

// Return value from courseDetail(courseId:).
struct OpenGolfCourseDetail {
    let holes: [OpenGolfHoleData]
    let postalCode: String?
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

    // Search: /v1/courses/search?q=…  →  { courses: [...] }
    func search(query: String) async throws -> [OpenGolfSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var comps = URLComponents(url: base.appendingPathComponent("v1/courses/search"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        let url = comps.url!
        print("[OpenGolfAPI] GET \(url)")
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse {
            print("[OpenGolfAPI] HTTP \(http.statusCode)")
        }
        try checkHTTP(response)
        do {
            struct SearchResponse: Decodable { let courses: [OpenGolfSearchResult] }
            return try JSONDecoder().decode(SearchResponse.self, from: data).courses
        } catch {
            print("[OpenGolfAPI] search decode error: \(error)")
            throw error
        }
    }

    // Course detail: /api/v1/courses/{id}  →  holes_data + postal_code.
    // Returns empty holes when holes_data is absent or null; validator turns that into noHoleData.
    func courseDetail(courseId: String) async throws -> OpenGolfCourseDetail {
        let url = base.appendingPathComponent("api/v1/courses/\(courseId)")
        print("[OpenGolfAPI] GET \(url)")
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse {
            print("[OpenGolfAPI] HTTP \(http.statusCode)")
        }
        try checkHTTP(response)
        do {
            struct CourseDetailResponse: Decodable {
                let holesData: [OpenGolfHoleData]?
                let postalCode: String?
                enum CodingKeys: String, CodingKey {
                    case holesData  = "holes_data"
                    case postalCode = "postal_code"
                }
                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    holesData  = try? c.decode([OpenGolfHoleData].self, forKey: .holesData)
                    postalCode = try? c.decode(String.self,            forKey: .postalCode)
                }
            }
            let decoded = try JSONDecoder().decode(CourseDetailResponse.self, from: data)
            let sortedHoles = (decoded.holesData ?? []).sorted { $0.holeNumber < $1.holeNumber }
            return OpenGolfCourseDetail(holes: sortedHoles, postalCode: decoded.postalCode)
        } catch {
            print("[OpenGolfAPI] course detail decode error: \(error)")
            throw error
        }
    }

    private func checkHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

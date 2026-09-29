import Foundation

/// Role: Work. Typed transport failures. DTO decode never crashes the crate.
enum SeekFault: Error, Equatable, Sendable {
    case cancelled
    case missing
    case transport
    case malformed
}

/// Role: Work. One HTTP hop. Injected so tests never leave the process.
protocol SeekCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Work. URLSession hop, 15 s timeout, app User-Agent on every request.
struct SeekSessionCarrier: SeekCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = CatalogClient.timeout
        configuration.timeoutIntervalForResource = CatalogClient.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": CatalogClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

struct MetSearchDTO: Decodable, Sendable {
    var total: Int?
    var objectIDs: [Int]?

    enum CodingKeys: String, CodingKey {
        case total
        case objectIDs
    }
}

struct MetObjectDTO: Decodable, Sendable {
    var objectID: Int?
    var artistDisplayName: String?
    var title: String?
    var primaryImageSmall: String?
    var isPublicDomain: Bool?
    var objectURL: String?
    var accessionNumber: String?

    enum CodingKeys: String, CodingKey {
        case objectID
        case artistDisplayName
        case title
        case primaryImageSmall
        case isPublicDomain
        case objectURL
        case accessionNumber
    }

    func asRow() -> CatalogRow? {
        guard let objectID, objectID > 0 else { return nil }
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedArtist = artistDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedTitle.isEmpty, !trimmedArtist.isEmpty else { return nil }
        let accession = (accessionNumber?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
            $0.isEmpty ? nil : $0
        } ?? "met-\(objectID)"
        let image = primaryImageSmall?.trimmingCharacters(in: .whitespacesAndNewlines)
        let href = objectURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        return CatalogRow(
            objectID: objectID,
            accession: accession,
            artist: trimmedArtist,
            title: trimmedTitle,
            imageHref: (image?.isEmpty == false) ? image : nil,
            objectHref: (href?.isEmpty == false) ? href : nil,
            isPublicDomain: isPublicDomain ?? false
        )
    }
}

/// Role: Work. Owns Met search. cgi search pl maps to q, hasImages, then page/page_size slice. Never Open Food Facts. DTO then domain.
actor CatalogClient {
    static let userAgent = "Tetraptych/1.0 (iOS; +https://tetraptych-lineup.pro)"
    static let timeout: TimeInterval = 15
    static let searchHost = "collectionapi.metmuseum.org"
    static let searchPath = "/public/collection/v1/search"
    static let objectPathPrefix = "/public/collection/v1/objects"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://tetraptych-lineup.pro/contact-us")!
    /// Programmer constant; Met credit lives on Settings.
    static let metHomeURL = URL(string: "https://www.metmuseum.org")!
    static let metOpenAccessURL = URL(string: "https://www.metmuseum.org/policies/open-access")!
    static let searchURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/search")!

    private let carrier: any SeekCarrying
    private let decoder: JSONDecoder

    init(carrier: any SeekCarrying) {
        self.carrier = carrier
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        self.init(carrier: SeekSessionCarrier())
    }

    func search(query: String, page: Int = 1, pageSize: Int = 8) async throws -> [CatalogRow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = Self.searchRequest(query: trimmed)
        let data = try await send(request)
        let dto: MetSearchDTO
        do {
            dto = try decoder.decode(MetSearchDTO.self, from: data)
        } catch is CancellationError {
            throw SeekFault.cancelled
        } catch {
            throw SeekFault.malformed
        }
        let ids = dto.objectIDs ?? []
        let pageIndex = max(page, 1)
        let size = min(max(pageSize, 1), 100)
        let start = (pageIndex - 1) * size
        guard start < ids.count else { return [] }
        let sliced = Array(ids[start..<min(start + size, ids.count)])
        var rows: [CatalogRow] = []
        rows.reserveCapacity(sliced.count)
        for objectID in sliced {
            try Task.checkCancellation()
            guard let row = try await fetchObject(objectID) else { continue }
            rows.append(row)
        }
        let preferred = rows.filter { $0.isPublicDomain && $0.imageHref != nil }
        return preferred.isEmpty ? rows : preferred
    }

    nonisolated static func searchRequest(query: String) -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = searchPath
        parts.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "hasImages", value: "true"),
        ]
        var request = URLRequest(url: parts.url ?? searchURL, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func objectRequest(objectID: Int) -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = "\(objectPathPrefix)/\(objectID)"
        let fallback = URL(string: "https://collectionapi.metmuseum.org\(objectPathPrefix)/\(objectID)") ?? searchURL
        var request = URLRequest(url: parts.url ?? fallback, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func fetchObject(_ objectID: Int) async throws -> CatalogRow? {
        let request = Self.objectRequest(objectID: objectID)
        do {
            let data = try await send(request)
            let dto: MetObjectDTO
            do {
                dto = try decoder.decode(MetObjectDTO.self, from: data)
            } catch is CancellationError {
                throw SeekFault.cancelled
            } catch {
                return nil
            }
            return dto.asRow()
        } catch SeekFault.missing {
            return nil
        }
    }

    private func send(_ request: URLRequest, retry: Bool = true) async throws -> Data {
        do {
            try Task.checkCancellation()
            let (data, response) = try await carrier.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw SeekFault.transport
            }
            if http.statusCode == 404 {
                throw SeekFault.missing
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                if retry {
                    return try await send(request, retry: false)
                }
                throw SeekFault.transport
            }
            return data
        } catch is CancellationError {
            throw SeekFault.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw SeekFault.cancelled
        } catch let fault as SeekFault {
            throw fault
        } catch {
            if retry, Self.transient(error) {
                return try await send(request, retry: false)
            }
            throw SeekFault.transport
        }
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}

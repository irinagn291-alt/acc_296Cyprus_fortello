import XCTest
@testable import Tetraptych

final class CatalogClientTests: XCTestCase {
    func testCgiSearchPlMapsOntoMetQHasImagesThenPageSlice() throws {
        let request = CatalogClient.searchRequest(query: "gogh")
        let url = try XCTUnwrap(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let keyed = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(url.host, "collectionapi.metmuseum.org")
        XCTAssertEqual(url.path, "/public/collection/v1/search")
        XCTAssertEqual(keyed["q"], "gogh")
        XCTAssertEqual(keyed["hasImages"], "true")
        XCTAssertNil(keyed["search_terms"])
        XCTAssertNil(keyed["page"])
        XCTAssertNil(keyed["page_size"])
        XCTAssertFalse(url.absoluteString.contains("openfoodfacts"))
        XCTAssertFalse(url.absoluteString.contains("cgi/search.pl"))
        XCTAssertFalse(url.absoluteString.contains("api.artic.edu"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(request.timeoutInterval, 15)

        let object = CatalogClient.objectRequest(objectID: 436535)
        let objectURL = try XCTUnwrap(object.url)
        XCTAssertEqual(objectURL.host, "collectionapi.metmuseum.org")
        XCTAssertEqual(objectURL.path, "/public/collection/v1/objects/436535")
        XCTAssertEqual(object.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
    }

    func testDTOMapsCamelCaseThenDomainRow() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((MetFixtures.searchJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
            .success((MetFixtures.goghJSON, MetFixtures.response(MetFixtures.objectURL(436535), 200))),
            .success((MetFixtures.vermeerJSON, MetFixtures.response(MetFixtures.objectURL(437881), 200))),
            .success((MetFixtures.homerJSON, MetFixtures.response(MetFixtures.objectURL(11122), 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "gogh", page: 1, pageSize: 3)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.objectID, 436535)
        XCTAssertEqual(row.accession, "1993.132")
        XCTAssertEqual(row.artist, "Vincent van Gogh")
        XCTAssertEqual(row.title, "Wheat Field with Cypresses")
        XCTAssertEqual(row.imageHref, "https://images.metmuseum.org/CRDImages/ep/web-large/DP-42549-001.jpg")
        XCTAssertTrue(row.isPublicDomain)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(rows.count, 3)
    }

    func testPageAndPageSizeSliceObjectIDs() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((MetFixtures.searchJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
            .success((MetFixtures.vermeerJSON, MetFixtures.response(MetFixtures.objectURL(437881), 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "vermeer", page: 2, pageSize: 1)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.objectID, 437881)
        let requests = await carrier.recordedRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[1].url?.path, "/public/collection/v1/objects/437881")
    }

    func testPrefersPublicDomainWithImage() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((MetFixtures.twoIDsJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
            .success((MetFixtures.restrictedJSON, MetFixtures.response(MetFixtures.objectURL(1), 200))),
            .success((MetFixtures.goghJSON, MetFixtures.response(MetFixtures.objectURL(436535), 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "hopper")
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.objectID, 436535)
        XCTAssertNotNil(rows.first?.imageHref)
    }

    func testTransientTransportRetriesOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((MetFixtures.oneIDJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
            .success((MetFixtures.goghJSON, MetFixtures.response(MetFixtures.objectURL(436535), 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "gogh")
        XCTAssertEqual(rows.count, 1)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 3)
    }

    func testDoesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), MetFixtures.response(MetFixtures.searchURL, 404))),
            .success((MetFixtures.searchJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        do {
            _ = try await client.search(query: "gogh")
            XCTFail("expected missing")
        } catch {
            XCTAssertEqual(error as? SeekFault, .missing)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func testMalformedJSONIsHandled() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("not-json".utf8), MetFixtures.response(MetFixtures.searchURL, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        do {
            _ = try await client.search(query: "gogh")
            XCTFail("malformed")
        } catch {
            XCTAssertEqual(error as? SeekFault, .malformed)
        }
    }

    func testEmptyQueryDoesNotHitNetwork() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((MetFixtures.searchJSON, MetFixtures.response(MetFixtures.searchURL, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "   ")
        XCTAssertTrue(rows.isEmpty)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 0)
    }
}

private actor ScriptedCarrier: SeekCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

enum MetFixtures {
    static let searchURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/search")!

    static func objectURL(_ id: Int) -> URL {
        URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects/\(id)")!
    }

    static let searchJSON = Data(
        """
        {"total":3,"objectIDs":[436535,437881,11122]}
        """.utf8
    )

    static let oneIDJSON = Data(
        """
        {"total":1,"objectIDs":[436535]}
        """.utf8
    )

    static let twoIDsJSON = Data(
        """
        {"total":2,"objectIDs":[1,436535]}
        """.utf8
    )

    static let goghJSON = Data(
        """
        {"objectID":436535,"artistDisplayName":"Vincent van Gogh","title":"Wheat Field with Cypresses","primaryImageSmall":"https://images.metmuseum.org/CRDImages/ep/web-large/DP-42549-001.jpg","isPublicDomain":true,"objectURL":"https://www.metmuseum.org/art/collection/search/436535","accessionNumber":"1993.132"}
        """.utf8
    )

    static let vermeerJSON = Data(
        """
        {"objectID":437881,"artistDisplayName":"Johannes Vermeer","title":"Young Woman with a Water Pitcher","primaryImageSmall":"https://images.metmuseum.org/CRDImages/ep/web-large/DP353257.jpg","isPublicDomain":true,"objectURL":"https://www.metmuseum.org/art/collection/search/437881","accessionNumber":"89.15.21"}
        """.utf8
    )

    static let homerJSON = Data(
        """
        {"objectID":11122,"artistDisplayName":"Winslow Homer","title":"The Gulf Stream","primaryImageSmall":"https://images.metmuseum.org/CRDImages/ad/web-large/DP-20821-001.jpg","isPublicDomain":true,"objectURL":"https://www.metmuseum.org/art/collection/search/11122","accessionNumber":"06.1234"}
        """.utf8
    )

    static let restrictedJSON = Data(
        """
        {"objectID":1,"artistDisplayName":"Restricted Studio","title":"Closed Gallery","primaryImageSmall":"","isPublicDomain":false,"objectURL":"https://www.metmuseum.org/art/collection/search/1","accessionNumber":"x.1"}
        """.utf8
    )

    static func response(_ url: URL, _ code: Int) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    }
}

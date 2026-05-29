import Foundation
import MCP
import Testing
@testable import asc_mcp

@Suite("Subscriptions v3 Worker Tests")
struct SubscriptionsV3WorkerTests {
    @Test("old offer worker prefixes are not public in v3")
    func oldOfferWorkerPrefixesAreNotPublic() async throws {
        let manager = try await TestFactory.makeWorkerManager(enabledWorkers: ["subscriptions"])

        let oldOffer = try await manager.routeTool(CallTool.Parameters(
            name: "offer_codes_list",
            arguments: ["subscription_id": .string("sub-1")]
        ))
        let oldIntro = try await manager.routeTool(CallTool.Parameters(
            name: "intro_offers_list",
            arguments: ["subscription_id": .string("sub-1")]
        ))
        let newOffer = try await manager.routeTool(CallTool.Parameters(
            name: "subscriptions_list_offer_codes",
            arguments: nil
        ))

        #expect(oldOffer.isError == true)
        #expect(oldIntro.isError == true)
        #expect(newOffer.isError == true)
        #expect(text(oldOffer).contains("Unknown tool"))
        #expect(text(oldIntro).contains("Unknown tool"))
        #expect(text(newOffer).contains("subscription_id"))
    }

    @Test("list subscription prices filters by territory and returns price point and currency")
    func listPricesFiltersByTerritoryAndReturnsCurrency() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionPrices",
                  "id": "price-1",
                  "attributes": {"startDate": "2026-05-01", "preserved": false},
                  "relationships": {
                    "territory": {"data": {"type": "territories", "id": "USA"}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": "pp-usa-999"}}
                  }
                }
              ],
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}},
                {"type": "subscriptionPricePoints", "id": "pp-usa-999", "attributes": {"customerPrice": "9.99", "proceeds": "7.00", "proceedsYear2": "8.50"}}
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_prices",
            arguments: [
                "subscription_id": .string("sub-1"),
                "territory_id": .string("USA"),
                "limit": .int(200)
            ]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptions/sub-1/prices")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["include"] == "territory,subscriptionPricePoint")
        #expect(query["fields[territories]"] == "currency")

        let root = try object(result.structuredContent)
        let prices = try array(root["prices"])
        let price = try object(prices.first)
        #expect(price["territory_id"] == .string("USA"))
        #expect(price["currency"] == .string("USD"))
        #expect(price["price_point_id"] == .string("pp-usa-999"))
        #expect(price["customer_price"] == .string("9.99"))
        #expect(price["proceeds_year2"] == .string("8.50"))
    }

    @Test("list subscription price points supports territory and 8000 limit")
    func listPricePointsSupportsTerritoryAndLargeLimit() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionPricePoints",
                  "id": "pp-1",
                  "attributes": {"customerPrice": "9.99", "proceeds": "7.00", "proceedsYear2": "8.50"},
                  "relationships": {"territory": {"data": {"type": "territories", "id": "USA"}}}
                }
              ],
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}}
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_price_points",
            arguments: [
                "subscription_id": .string("sub-1"),
                "territory_id": .string("USA"),
                "limit": .int(8000)
            ]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptions/sub-1/pricePoints")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["include"] == "territory")
        #expect(query["limit"] == "8000")

        let root = try object(result.structuredContent)
        let points = try array(root["price_points"])
        let point = try object(points.first)
        #expect(point["territory_id"] == .string("USA"))
        #expect(point["currency"] == .string("USD"))
        #expect(point["customer_price"] == .string("9.99"))
    }

    @Test("price point equalizations use Apple filters and large limit")
    func pricePointEqualizationsUseFilters() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: #"{"data":[]}"#)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_price_point_equalizations",
            arguments: [
                "price_point_id": .string("pp-1"),
                "subscription_id": .string("sub-1"),
                "territory_id": .string("USA"),
                "limit": .int(8000)
            ]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptionPricePoints/pp-1/equalizations")
        #expect(query["filter[subscription]"] == "sub-1")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["limit"] == "8000")
    }

    @Test("get subscription availability includes available territories")
    func getAvailabilityIncludesTerritories() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": {
                "type": "subscriptionAvailabilities",
                "id": "avail-1",
                "attributes": {"availableInNewTerritories": true},
                "relationships": {"availableTerritories": {"data": [{"type": "territories", "id": "USA"}]}}
              },
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}}
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_get_availability",
            arguments: ["subscription_id": .string("sub-1")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptions/sub-1/subscriptionAvailability")
        #expect(query["include"] == "availableTerritories")
        let root = try object(result.structuredContent)
        let availability = try object(root["availability"])
        let territories = try array(availability["available_territories"])
        let territory = try object(territories.first)
        #expect(availability["available_in_new_territories"] == .bool(true))
        #expect(territory["id"] == .string("USA"))
        #expect(territory["currency"] == .string("USD"))
    }

    @Test("promotional offer creation rejects mismatched price point and territory arrays before network")
    func promotionalOfferRejectsMismatchedPriceArrays() async throws {
        let transport = TestHTTPTransport(responses: [])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_create_promotional_offer",
            arguments: [
                "subscription_id": .string("sub-1"),
                "name": .string("Launch"),
                "offer_code": .string("LAUNCH"),
                "duration": .string("ONE_MONTH"),
                "offer_mode": .string("PAY_UP_FRONT"),
                "number_of_periods": .int(1),
                "territory_ids": .array([.string("USA"), .string("GBR")]),
                "price_point_ids": .array([.string("pp-usa")])
            ]
        ))

        #expect(result.isError == true)
        #expect(await transport.requestCount() == 0)
        #expect(text(result).contains("same count"))
    }

    @Test("introductory offer creation preserves territory_id for Apple relationship")
    func introductoryOfferCreateKeepsTerritoryID() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": {
                "type": "subscriptionIntroductoryOffers",
                "id": "intro-1",
                "attributes": {"duration": "ONE_MONTH", "offerMode": "FREE_TRIAL", "numberOfPeriods": 1}
              }
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_create_intro_offer",
            arguments: [
                "subscription_id": .string("sub-1"),
                "duration": .string("ONE_MONTH"),
                "offer_mode": .string("FREE_TRIAL"),
                "number_of_periods": .int(1),
                "territory_id": .string("USA")
            ]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        #expect(request.url?.path == "/v1/subscriptionIntroductoryOffers")
        let body = try #require(await transport.recordedBodyStrings().first)
        #expect(
            body.contains(#""territory":{"data":{"type":"territories","id":"USA"}}"#)
                || body.contains(#""territory":{"data":{"id":"USA","type":"territories"}}"#)
        )
        #expect(!body.contains("filter_territory"))
    }

    @Test("list subscription promotional offers supports territory filter")
    func listPromotionalOffersSupportsTerritoryFilter() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionPromotionalOffers",
                  "id": "promo-1",
                  "attributes": {"name": "Launch", "offerCode": "LAUNCH"},
                  "relationships": {
                    "prices": {"data": [{"type": "subscriptionPromotionalOfferPrices", "id": "promo-price-1"}]}
                  }
                }
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_promotional_offers",
            arguments: ["subscription_id": .string("sub-1"), "territory_id": .string("USA")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptions/sub-1/promotionalOffers")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["include"] == "prices")
        let root = try object(result.structuredContent)
        let offer = try object(try array(root["promotional_offers"]).first)
        #expect(offer["offer_code"] == .string("LAUNCH"))
        #expect(offer["prices_ids"] == .array([.string("promo-price-1")]))
    }

    @Test("list subscription offer codes supports territory filter")
    func listOfferCodesSupportsTerritoryFilter() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionOfferCodes",
                  "id": "offer-1",
                  "attributes": {"name": "Launch", "active": true},
                  "relationships": {
                    "prices": {"data": [{"type": "subscriptionOfferCodePrices", "id": "offer-price-1"}]}
                  }
                }
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_offer_codes",
            arguments: ["subscription_id": .string("sub-1"), "territory_id": .string("USA")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptions/sub-1/offerCodes")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["include"] == "oneTimeUseCodes,customCodes,prices")
        let root = try object(result.structuredContent)
        let offer = try object(try array(root["offer_codes"]).first)
        #expect(offer["name"] == .string("Launch"))
        #expect(offer["prices_ids"] == .array([.string("offer-price-1")]))
    }

    @Test("subscription offer code get uses direct v3 endpoint")
    func offerCodeGetUsesDirectEndpoint() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": {
                "type": "subscriptionOfferCodes",
                "id": "offer-1",
                "attributes": {"name": "Launch", "active": true}
              }
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_get_offer_code",
            arguments: ["offer_code_id": .string("offer-1")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        #expect(request.url?.path == "/v1/subscriptionOfferCodes/offer-1")
        let root = try object(result.structuredContent)
        let offer = try object(root["offer_code"])
        #expect(offer["id"] == .string("offer-1"))
        #expect(offer["name"] == .string("Launch"))
        #expect(offer["active"] == .bool(true))
    }

    @Test("subscription offer code prices support territory filter and normalized price fields")
    func offerCodePricesSupportTerritoryFilter() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionOfferCodePrices",
                  "id": "offer-price-1",
                  "relationships": {
                    "territory": {"data": {"type": "territories", "id": "USA"}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": "pp-1"}}
                  }
                }
              ],
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}},
                {"type": "subscriptionPricePoints", "id": "pp-1", "attributes": {"customerPrice": "1.99", "proceeds": "1.40", "proceedsYear2": "1.70"}}
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_list_offer_code_prices",
            arguments: ["offer_code_id": .string("offer-1"), "territory_id": .string("USA")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        let query = queryItems(request)
        #expect(request.url?.path == "/v1/subscriptionOfferCodes/offer-1/prices")
        #expect(query["filter[territory]"] == "USA")
        #expect(query["include"] == "territory,subscriptionPricePoint")

        let root = try object(result.structuredContent)
        let price = try object(try array(root["prices"]).first)
        #expect(price["territory_id"] == .string("USA"))
        #expect(price["currency"] == .string("USD"))
        #expect(price["price_point_id"] == .string("pp-1"))
        #expect(price["customer_price"] == .string("1.99"))
        #expect(price["proceeds_year2"] == .string("1.70"))
    }

    @Test("subscription win-back offer get uses direct v3 endpoint")
    func winBackOfferGetUsesDirectEndpoint() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": {
                "type": "winBackOffers",
                "id": "winback-1",
                "attributes": {"referenceName": "Come Back", "offerId": "comeback"}
              }
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_get_winback_offer",
            arguments: ["winback_offer_id": .string("winback-1")]
        ))

        #expect(result.isError != true)
        let request = try #require(await transport.recordedRequests().first)
        #expect(request.url?.path == "/v1/winBackOffers/winback-1")
        let root = try object(result.structuredContent)
        let offer = try object(root["win_back_offer"])
        #expect(offer["id"] == .string("winback-1"))
        #expect(offer["reference_name"] == .string("Come Back"))
    }

    @Test("subscription inventory includes availability and current territory price when territory is provided")
    func inventoryIncludesAvailabilityAndCurrentPrice() async throws {
        let transport = TestHTTPTransport(responses: [
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionGroups",
                  "id": "group-1",
                  "attributes": {"referenceName": "Main"},
                  "relationships": {"subscriptions": {"data": [{"type": "subscriptions", "id": "sub-1"}]}}
                }
              ],
              "included": [
                {"type": "subscriptions", "id": "sub-1", "attributes": {"name": "Premium", "productId": "premium.monthly", "state": "APPROVED"}}
              ]
            }
            """),
            .init(statusCode: 200, body: """
            {
              "data": {
                "type": "subscriptionAvailabilities",
                "id": "avail-1",
                "attributes": {"availableInNewTerritories": true},
                "relationships": {"availableTerritories": {"data": [{"type": "territories", "id": "USA"}]}}
              },
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}}
              ]
            }
            """),
            .init(statusCode: 200, body: """
            {
              "data": [
                {
                  "type": "subscriptionPrices",
                  "id": "price-1",
                  "attributes": {"startDate": "2026-01-01", "preserved": false},
                  "relationships": {
                    "territory": {"data": {"type": "territories", "id": "USA"}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": "pp-1"}}
                  }
                }
              ],
              "included": [
                {"type": "territories", "id": "USA", "attributes": {"currency": "USD"}},
                {"type": "subscriptionPricePoints", "id": "pp-1", "attributes": {"customerPrice": "9.99", "proceeds": "7.00", "proceedsYear2": "8.50"}}
              ]
            }
            """)
        ])
        let worker = try await makeWorker(transport: transport)

        let result = try await worker.handleTool(CallTool.Parameters(
            name: "subscriptions_inventory",
            arguments: ["app_id": .string("app-1"), "territory_id": .string("USA")]
        ))

        #expect(result.isError != true)
        let requests = await transport.recordedRequests()
        #expect(requests.map { $0.url?.path } == [
            "/v1/apps/app-1/subscriptionGroups",
            "/v1/subscriptions/sub-1/subscriptionAvailability",
            "/v1/subscriptions/sub-1/prices"
        ])

        let root = try object(result.structuredContent)
        let subscription = try object(try array(root["subscriptions"]).first)
        let availability = try object(subscription["availability"])
        let currentPrice = try object(subscription["current_price"])
        #expect(subscription["id"] == .string("sub-1"))
        #expect(availability["available_in_new_territories"] == .bool(true))
        #expect(currentPrice["territory_id"] == .string("USA"))
        #expect(currentPrice["currency"] == .string("USD"))
        #expect(currentPrice["customer_price"] == .string("9.99"))
    }
}

private func makeWorker(transport: TestHTTPTransport) async throws -> SubscriptionsWorker {
    let client = await HTTPClient(
        jwtService: try TestFactory.makeJWTService(),
        baseURL: "https://api.example.test",
        transport: transport,
        maxRetries: 1
    )
    return SubscriptionsWorker(httpClient: client, uploadService: UploadService())
}

private func queryItems(_ request: URLRequest) -> [String: String] {
    let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
    return Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item in
        item.value.map { (item.name, $0) }
    })
}

private func object(_ value: Value?) throws -> [String: Value] {
    guard case .object(let object) = value else {
        Issue.record("Expected object, got \(String(describing: value))")
        throw SubscriptionsV3TestFailure.expectedObject
    }
    return object
}

private func array(_ value: Value?) throws -> [Value] {
    guard case .array(let array) = value else {
        Issue.record("Expected array, got \(String(describing: value))")
        throw SubscriptionsV3TestFailure.expectedArray
    }
    return array
}

private func text(_ result: CallTool.Result) -> String {
    result.content.compactMap { content in
        if case .text(let text, _, _) = content {
            return text
        }
        return nil
    }.joined(separator: "\n")
}

private enum SubscriptionsV3TestFailure: Error {
    case expectedObject
    case expectedArray
}

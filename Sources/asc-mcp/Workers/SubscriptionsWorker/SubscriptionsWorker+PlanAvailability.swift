import Foundation
import MCP

// MARK: - Plan Availability & Group Submission (API 4.4)
extension SubscriptionsWorker {

    func planAvailabilityTools() -> [Tool] {
        [
            createPlanAvailabilityTool(),
            listPlanAvailabilitiesTool()
        ]
    }

    // MARK: Tool Definitions

    func createPlanAvailabilityTool() -> Tool {
        Tool(
            name: "subscriptions_create_plan_availability",
            description: "Set per-plan territory availability for a subscription (API 4.4 successor to per-subscription availability). plan_type MONTHLY = standard auto-renewing plan; UPFRONT = prepaid plan. Provide the territory IDs the plan is available in.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "subscription_id": .object(["type": .string("string"), "description": .string("Subscription ID")]),
                    "plan_type": .object(["type": .string("string"), "description": .string("Plan type: MONTHLY (standard auto-renewing) or UPFRONT (prepaid)")]),
                    "territory_ids": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("Territory IDs the plan is available in (e.g. USA, GBR). Get IDs from pricing_list_territories.")]),
                    "available_in_new_territories": .object(["type": .string("boolean"), "description": .string("Auto-enable in territories Apple adds later (default false)")])
                ]),
                "required": .array([.string("subscription_id"), .string("plan_type"), .string("territory_ids")])
            ])
        )
    }

    func listPlanAvailabilitiesTool() -> Tool {
        Tool(
            name: "subscriptions_list_plan_availabilities",
            description: "List per-plan availabilities for a subscription (MONTHLY / UPFRONT), each with its territory set.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "subscription_id": .object(["type": .string("string"), "description": .string("Subscription ID")]),
                    "limit": .object(["type": .string("integer"), "description": .string("Max results (default: 25, max: 200)")])
                ]),
                "required": .array([.string("subscription_id")])
            ])
        )
    }

    // MARK: Handlers

    /// Creates per-plan territory availability for a subscription (MONTHLY / UPFRONT).
    func createPlanAvailability(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let subscriptionID = arguments["subscription_id"]?.stringValue,
              let planType = arguments["plan_type"]?.stringValue else {
            return MCPResult.error("Required parameters: subscription_id, plan_type, territory_ids")
        }

        let territoryIds = arguments["territory_ids"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        guard !territoryIds.isEmpty else {
            return MCPResult.error("'territory_ids' must contain at least one territory ID")
        }

        do {
            let request = CreateSubscriptionPlanAvailabilityRequest(
                data: CreateSubscriptionPlanAvailabilityRequest.CreateData(
                    attributes: CreateSubscriptionPlanAvailabilityRequest.Attributes(
                        planType: planType,
                        availableInNewTerritories: arguments["available_in_new_territories"]?.boolValue
                    ),
                    relationships: CreateSubscriptionPlanAvailabilityRequest.Relationships(
                        subscription: CreateSubscriptionPlanAvailabilityRequest.SubscriptionRelationship(
                            data: ASCResourceIdentifier(type: "subscriptions", id: subscriptionID)
                        ),
                        availableTerritories: CreateSubscriptionPlanAvailabilityRequest.TerritoriesRelationship(
                            data: territoryIds.map { ASCResourceIdentifier(type: "territories", id: $0) }
                        )
                    )
                )
            )

            let response: ASCSubscriptionPlanAvailabilityResponse = try await httpClient.post(
                "/v1/subscriptionPlanAvailabilities",
                body: request,
                as: ASCSubscriptionPlanAvailabilityResponse.self
            )

            return MCPResult.jsonObject([
                "success": true,
                "plan_availability": formatPlanAvailability(response.data),
                "territories_count": territoryIds.count
            ])
        } catch {
            return MCPResult.error("Failed to create plan availability: \(error.localizedDescription)")
        }
    }

    /// Lists per-plan availabilities for a subscription.
    func listPlanAvailabilities(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let subscriptionID = arguments["subscription_id"]?.stringValue else {
            return MCPResult.error("Required parameter 'subscription_id' is missing")
        }

        do {
            var query: [String: String] = [:]
            if let limit = arguments["limit"]?.intValue {
                query["limit"] = String(min(max(limit, 1), 200))
            } else {
                query["limit"] = "25"
            }

            let response: ASCSubscriptionPlanAvailabilitiesResponse = try await httpClient.get(
                "/v1/subscriptions/\(subscriptionID)/planAvailabilities",
                parameters: query,
                as: ASCSubscriptionPlanAvailabilitiesResponse.self
            )

            return MCPResult.jsonObject([
                "success": true,
                "plan_availabilities": response.data.map(formatPlanAvailability),
                "count": response.data.count
            ])
        } catch {
            return MCPResult.error("Failed to list plan availabilities: \(error.localizedDescription)")
        }
    }

    private func formatPlanAvailability(_ availability: ASCSubscriptionPlanAvailability) -> [String: Any] {
        [
            "id": availability.id,
            "type": availability.type,
            "planType": availability.attributes?.planType.jsonSafe ?? NSNull(),
            "availableInNewTerritories": availability.attributes?.availableInNewTerritories ?? NSNull()
        ]
    }
}

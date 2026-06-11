import Foundation
import MCP

extension NominationsWorker {

    /// Lists App Store nominations with optional type/state/app filtering.
    func listNominations(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let arguments = params.arguments

        do {
            let response: ASCNominationsResponse

            if let nextURL = arguments?["next_url"]?.stringValue {
                guard let parsed = await httpClient.parsePaginationUrl(nextURL) else {
                    return MCPResult.error("Parameter 'next_url' must be an App Store Connect API pagination URL")
                }
                response = try await httpClient.get(parsed.path, parameters: parsed.parameters, as: ASCNominationsResponse.self)
            } else {
                var query: [String: String] = [:]
                if let filterType = arguments?["filter_type"]?.stringValue {
                    query["filter[type]"] = filterType
                }
                if let filterState = arguments?["filter_state"]?.stringValue {
                    query["filter[state]"] = filterState
                }
                if let appID = arguments?["app_id"]?.stringValue {
                    query["filter[relatedApps]"] = appID
                }
                if let limit = arguments?["limit"]?.intValue {
                    query["limit"] = String(min(max(limit, 1), 200))
                } else {
                    query["limit"] = "25"
                }
                response = try await httpClient.get("/v1/nominations", parameters: query, as: ASCNominationsResponse.self)
            }

            var result: [String: Any] = [
                "success": true,
                "nominations": response.data.map(formatNomination),
                "count": response.data.count
            ]
            if let next = response.links?.next {
                result["next_url"] = next
            }
            return MCPResult.jsonObject(result)
        } catch {
            return MCPResult.error("Failed to list nominations: \(error.localizedDescription)")
        }
    }

    /// Gets a single nomination by ID.
    func getNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationID = arguments["nomination_id"]?.stringValue else {
            return MCPResult.error("Required parameter 'nomination_id' is missing")
        }

        do {
            let response: ASCNominationResponse = try await httpClient.get(
                "/v1/nominations/\(nominationID)",
                parameters: [:],
                as: ASCNominationResponse.self
            )
            return MCPResult.jsonObject(["success": true, "nomination": formatNomination(response.data)])
        } catch {
            return MCPResult.error("Failed to get nomination: \(error.localizedDescription)")
        }
    }

    /// Creates a nomination (editorial featuring pitch).
    func createNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let name = arguments["name"]?.stringValue,
              let nominationType = arguments["nomination_type"]?.stringValue,
              let description = arguments["description"]?.stringValue,
              let publishStartDate = arguments["publish_start_date"]?.stringValue else {
            return MCPResult.error("Required parameters: name, nomination_type, description, publish_start_date, related_app_ids")
        }

        let relatedAppIds = arguments["related_app_ids"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        guard !relatedAppIds.isEmpty else {
            return MCPResult.error("'related_app_ids' must contain at least one app ID")
        }

        let inAppEventIds = arguments["in_app_event_ids"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        let territoryIds = arguments["territory_ids"]?.arrayValue?.compactMap { $0.stringValue } ?? []

        do {
            let request = CreateNominationRequest(
                data: CreateNominationRequest.CreateData(
                    attributes: CreateNominationRequest.Attributes(
                        name: name,
                        type: nominationType,
                        description: description,
                        submitted: arguments["submitted"]?.boolValue ?? false,
                        publishStartDate: publishStartDate,
                        publishEndDate: arguments["publish_end_date"]?.stringValue,
                        deviceFamilies: arguments["device_families"]?.arrayValue?.compactMap { $0.stringValue },
                        locales: arguments["locales"]?.arrayValue?.compactMap { $0.stringValue },
                        supplementalMaterialsUris: arguments["supplemental_materials_uris"]?.arrayValue?.compactMap { $0.stringValue },
                        hasInAppEvents: arguments["has_in_app_events"]?.boolValue,
                        launchInSelectMarketsFirst: arguments["launch_in_select_markets_first"]?.boolValue,
                        notes: arguments["notes"]?.stringValue,
                        preOrderEnabled: arguments["pre_order_enabled"]?.boolValue
                    ),
                    relationships: CreateNominationRequest.Relationships(
                        relatedApps: CreateNominationRequest.RelationshipData(
                            data: relatedAppIds.map { ASCResourceIdentifier(type: "apps", id: $0) }
                        ),
                        inAppEvents: inAppEventIds.isEmpty ? nil : CreateNominationRequest.RelationshipData(
                            data: inAppEventIds.map { ASCResourceIdentifier(type: "appEvents", id: $0) }
                        ),
                        supportedTerritories: territoryIds.isEmpty ? nil : CreateNominationRequest.RelationshipData(
                            data: territoryIds.map { ASCResourceIdentifier(type: "territories", id: $0) }
                        )
                    )
                )
            )

            let response: ASCNominationResponse = try await httpClient.post(
                "/v1/nominations",
                body: request,
                as: ASCNominationResponse.self
            )
            return MCPResult.jsonObject(["success": true, "nomination": formatNomination(response.data)])
        } catch {
            return MCPResult.error("Failed to create nomination: \(error.localizedDescription)")
        }
    }

    /// Updates / submits / archives a nomination.
    func updateNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationID = arguments["nomination_id"]?.stringValue else {
            return MCPResult.error("Required parameter 'nomination_id' is missing")
        }

        do {
            let request = UpdateNominationRequest(
                data: UpdateNominationRequest.UpdateData(
                    id: nominationID,
                    attributes: UpdateNominationRequest.Attributes(
                        name: arguments["name"]?.stringValue,
                        type: arguments["nomination_type"]?.stringValue,
                        description: arguments["description"]?.stringValue,
                        submitted: arguments["submitted"]?.boolValue,
                        archived: arguments["archived"]?.boolValue,
                        publishStartDate: arguments["publish_start_date"]?.stringValue,
                        publishEndDate: arguments["publish_end_date"]?.stringValue,
                        deviceFamilies: arguments["device_families"]?.arrayValue?.compactMap { $0.stringValue },
                        locales: arguments["locales"]?.arrayValue?.compactMap { $0.stringValue },
                        supplementalMaterialsUris: arguments["supplemental_materials_uris"]?.arrayValue?.compactMap { $0.stringValue },
                        hasInAppEvents: arguments["has_in_app_events"]?.boolValue,
                        launchInSelectMarketsFirst: arguments["launch_in_select_markets_first"]?.boolValue,
                        notes: arguments["notes"]?.stringValue,
                        preOrderEnabled: arguments["pre_order_enabled"]?.boolValue
                    )
                )
            )

            let response: ASCNominationResponse = try await httpClient.patch(
                "/v1/nominations/\(nominationID)",
                body: request,
                as: ASCNominationResponse.self
            )
            return MCPResult.jsonObject(["success": true, "nomination": formatNomination(response.data)])
        } catch {
            return MCPResult.error("Failed to update nomination: \(error.localizedDescription)")
        }
    }

    /// Deletes a nomination.
    func deleteNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationID = arguments["nomination_id"]?.stringValue else {
            return MCPResult.error("Required parameter 'nomination_id' is missing")
        }

        do {
            _ = try await httpClient.delete("/v1/nominations/\(nominationID)")
            return MCPResult.jsonObject(["success": true, "message": "Nomination '\(nominationID)' deleted"])
        } catch {
            return MCPResult.error("Failed to delete nomination: \(error.localizedDescription)")
        }
    }

    // MARK: - Formatting

    func formatNomination(_ nomination: ASCNomination) -> [String: Any] {
        var result: [String: Any] = [
            "id": nomination.id,
            "type": nomination.type
        ]

        if let attrs = nomination.attributes {
            result["name"] = attrs.name.jsonSafe
            result["nominationType"] = attrs.type.jsonSafe
            result["description"] = attrs.description.jsonSafe
            result["state"] = attrs.state.jsonSafe
            result["createdDate"] = attrs.createdDate.jsonSafe
            result["lastModifiedDate"] = attrs.lastModifiedDate.jsonSafe
            result["submittedDate"] = attrs.submittedDate.jsonSafe
            result["publishStartDate"] = attrs.publishStartDate.jsonSafe
            result["publishEndDate"] = attrs.publishEndDate.jsonSafe
            result["deviceFamilies"] = attrs.deviceFamilies ?? NSNull()
            result["locales"] = attrs.locales ?? NSNull()
            result["supplementalMaterialsUris"] = attrs.supplementalMaterialsUris ?? NSNull()
            result["hasInAppEvents"] = attrs.hasInAppEvents ?? NSNull()
            result["launchInSelectMarketsFirst"] = attrs.launchInSelectMarketsFirst ?? NSNull()
            result["notes"] = attrs.notes.jsonSafe
            result["preOrderEnabled"] = attrs.preOrderEnabled ?? NSNull()
        }

        return result
    }
}

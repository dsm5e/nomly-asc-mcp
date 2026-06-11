import Foundation
import MCP

// MARK: - Tool Handlers
extension NominationsWorker {

    /// Lists App Store nominations with optional type/state/app filtering
    /// - Returns: JSON array of nominations with state and schedule
    func listNominations(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let arguments = params.arguments

        do {
            let response: ASCNominationsResponse

            if let nextUrl = arguments?["next_url"]?.stringValue,
               let parsed = parsePaginationUrl(nextUrl) {
                response = try await httpClient.get(parsed.path, parameters: parsed.parameters, as: ASCNominationsResponse.self)
            } else {
                var queryParams: [String: String] = [:]

                if let filterType = arguments?["filter_type"]?.stringValue {
                    queryParams["filter[type]"] = filterType
                }
                if let filterState = arguments?["filter_state"]?.stringValue {
                    queryParams["filter[state]"] = filterState
                }
                if let appId = arguments?["app_id"]?.stringValue {
                    queryParams["filter[relatedApps]"] = appId
                }
                if let limit = arguments?["limit"]?.intValue {
                    queryParams["limit"] = String(min(max(limit, 1), 200))
                } else {
                    queryParams["limit"] = "25"
                }

                response = try await httpClient.get(
                    "/v1/nominations",
                    parameters: queryParams,
                    as: ASCNominationsResponse.self
                )
            }

            let nominations = response.data.map { formatNomination($0) }

            var result: [String: Any] = [
                "success": true,
                "nominations": nominations,
                "count": nominations.count
            ]
            if let next = response.links?.next {
                result["next_url"] = next
            }

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to list nominations: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Gets a single nomination by ID
    /// - Returns: JSON with nomination details
    func getNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationId = arguments["nomination_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'nomination_id' is missing")],
                isError: true
            )
        }

        do {
            let response: ASCNominationResponse = try await httpClient.get(
                "/v1/nominations/\(nominationId)",
                parameters: [:],
                as: ASCNominationResponse.self
            )

            let result = [
                "success": true,
                "nomination": formatNomination(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to get nomination: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Creates a nomination (editorial featuring pitch)
    /// - Returns: JSON with the created nomination
    func createNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let name = arguments["name"]?.stringValue,
              let nominationType = arguments["nomination_type"]?.stringValue,
              let description = arguments["description"]?.stringValue,
              let publishStartDate = arguments["publish_start_date"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameters: name, nomination_type, description, publish_start_date, related_app_ids")],
                isError: true
            )
        }

        let relatedAppIds = arguments["related_app_ids"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        guard !relatedAppIds.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: 'related_app_ids' must contain at least one app ID")],
                isError: true
            )
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

            let result = [
                "success": true,
                "nomination": formatNomination(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to create nomination: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Updates / submits / archives a nomination
    /// - Returns: JSON with the updated nomination
    func updateNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationId = arguments["nomination_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'nomination_id' is missing")],
                isError: true
            )
        }

        do {
            let request = UpdateNominationRequest(
                data: UpdateNominationRequest.UpdateData(
                    id: nominationId,
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
                "/v1/nominations/\(nominationId)",
                body: request,
                as: ASCNominationResponse.self
            )

            let result = [
                "success": true,
                "nomination": formatNomination(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to update nomination: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Deletes a nomination
    /// - Returns: JSON confirmation
    func deleteNomination(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let nominationId = arguments["nomination_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'nomination_id' is missing")],
                isError: true
            )
        }

        do {
            _ = try await httpClient.delete("/v1/nominations/\(nominationId)")

            let result = [
                "success": true,
                "message": "Nomination '\(nominationId)' deleted"
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to delete nomination: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    // MARK: - Formatting

    private func formatNomination(_ nomination: ASCNomination) -> [String: Any] {
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

import Foundation
import MCP

// MARK: - Tool Handlers
extension AccessibilityDeclarationsWorker {

    /// Lists accessibility declarations for an app
    /// - Returns: JSON array of declarations with device family, state, and feature flags
    func listAccessibilityDeclarations(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let appId = arguments["app_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'app_id' is missing")],
                isError: true
            )
        }

        do {
            var queryParams: [String: String] = [:]
            if let deviceFamily = arguments["filter_device_family"]?.stringValue {
                queryParams["filter[deviceFamily]"] = deviceFamily
            }
            if let state = arguments["filter_state"]?.stringValue {
                queryParams["filter[state]"] = state
            }
            if let limit = arguments["limit"]?.intValue {
                queryParams["limit"] = String(min(max(limit, 1), 200))
            } else {
                queryParams["limit"] = "25"
            }

            let response: ASCAccessibilityDeclarationsResponse = try await httpClient.get(
                "/v1/apps/\(appId)/accessibilityDeclarations",
                parameters: queryParams,
                as: ASCAccessibilityDeclarationsResponse.self
            )

            let declarations = response.data.map { formatDeclaration($0) }

            let result: [String: Any] = [
                "success": true,
                "accessibility_declarations": declarations,
                "count": declarations.count
            ]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to list accessibility declarations: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Gets a single accessibility declaration by ID
    /// - Returns: JSON with declaration details
    func getAccessibilityDeclaration(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let declarationId = arguments["declaration_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'declaration_id' is missing")],
                isError: true
            )
        }

        do {
            let response: ASCAccessibilityDeclarationResponse = try await httpClient.get(
                "/v1/accessibilityDeclarations/\(declarationId)",
                parameters: [:],
                as: ASCAccessibilityDeclarationResponse.self
            )

            let result = [
                "success": true,
                "accessibility_declaration": formatDeclaration(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to get accessibility declaration: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Creates a DRAFT accessibility declaration for an app + device family
    /// - Returns: JSON with the created declaration
    func createAccessibilityDeclaration(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let appId = arguments["app_id"]?.stringValue,
              let deviceFamily = arguments["device_family"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameters: app_id, device_family")],
                isError: true
            )
        }

        do {
            let request = CreateAccessibilityDeclarationRequest(
                data: CreateAccessibilityDeclarationRequest.CreateData(
                    attributes: CreateAccessibilityDeclarationRequest.Attributes(
                        deviceFamily: deviceFamily,
                        supportsAudioDescriptions: arguments["supports_audio_descriptions"]?.boolValue,
                        supportsCaptions: arguments["supports_captions"]?.boolValue,
                        supportsDarkInterface: arguments["supports_dark_interface"]?.boolValue,
                        supportsDifferentiateWithoutColorAlone: arguments["supports_differentiate_without_color_alone"]?.boolValue,
                        supportsLargerText: arguments["supports_larger_text"]?.boolValue,
                        supportsReducedMotion: arguments["supports_reduced_motion"]?.boolValue,
                        supportsSufficientContrast: arguments["supports_sufficient_contrast"]?.boolValue,
                        supportsVoiceControl: arguments["supports_voice_control"]?.boolValue,
                        supportsVoiceover: arguments["supports_voiceover"]?.boolValue
                    ),
                    relationships: CreateAccessibilityDeclarationRequest.Relationships(
                        app: CreateAccessibilityDeclarationRequest.AppRelationship(
                            data: ASCResourceIdentifier(type: "apps", id: appId)
                        )
                    )
                )
            )

            let response: ASCAccessibilityDeclarationResponse = try await httpClient.post(
                "/v1/accessibilityDeclarations",
                body: request,
                as: ASCAccessibilityDeclarationResponse.self
            )

            let result = [
                "success": true,
                "accessibility_declaration": formatDeclaration(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to create accessibility declaration: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Updates a DRAFT accessibility declaration or publishes it
    /// - Returns: JSON with the updated declaration
    func updateAccessibilityDeclaration(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let declarationId = arguments["declaration_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'declaration_id' is missing")],
                isError: true
            )
        }

        do {
            let request = UpdateAccessibilityDeclarationRequest(
                data: UpdateAccessibilityDeclarationRequest.UpdateData(
                    id: declarationId,
                    attributes: UpdateAccessibilityDeclarationRequest.Attributes(
                        publish: arguments["publish"]?.boolValue,
                        supportsAudioDescriptions: arguments["supports_audio_descriptions"]?.boolValue,
                        supportsCaptions: arguments["supports_captions"]?.boolValue,
                        supportsDarkInterface: arguments["supports_dark_interface"]?.boolValue,
                        supportsDifferentiateWithoutColorAlone: arguments["supports_differentiate_without_color_alone"]?.boolValue,
                        supportsLargerText: arguments["supports_larger_text"]?.boolValue,
                        supportsReducedMotion: arguments["supports_reduced_motion"]?.boolValue,
                        supportsSufficientContrast: arguments["supports_sufficient_contrast"]?.boolValue,
                        supportsVoiceControl: arguments["supports_voice_control"]?.boolValue,
                        supportsVoiceover: arguments["supports_voiceover"]?.boolValue
                    )
                )
            )

            let response: ASCAccessibilityDeclarationResponse = try await httpClient.patch(
                "/v1/accessibilityDeclarations/\(declarationId)",
                body: request,
                as: ASCAccessibilityDeclarationResponse.self
            )

            let result = [
                "success": true,
                "accessibility_declaration": formatDeclaration(response.data)
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to update accessibility declaration: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    /// Deletes an accessibility declaration
    /// - Returns: JSON confirmation
    func deleteAccessibilityDeclaration(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let arguments = params.arguments,
              let declarationId = arguments["declaration_id"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: Required parameter 'declaration_id' is missing")],
                isError: true
            )
        }

        do {
            _ = try await httpClient.delete("/v1/accessibilityDeclarations/\(declarationId)")

            let result = [
                "success": true,
                "message": "Accessibility declaration '\(declarationId)' deleted"
            ] as [String: Any]

            return CallTool.Result(content: [.text(JSONFormatter.formatJSON(result))])

        } catch {
            return CallTool.Result(
                content: [.text("Error: Failed to delete accessibility declaration: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    // MARK: - Formatting

    private func formatDeclaration(_ declaration: ASCAccessibilityDeclaration) -> [String: Any] {
        var result: [String: Any] = [
            "id": declaration.id,
            "type": declaration.type
        ]

        if let attrs = declaration.attributes {
            result["deviceFamily"] = attrs.deviceFamily.jsonSafe
            result["state"] = attrs.state.jsonSafe
            result["supportsAudioDescriptions"] = attrs.supportsAudioDescriptions ?? NSNull()
            result["supportsCaptions"] = attrs.supportsCaptions ?? NSNull()
            result["supportsDarkInterface"] = attrs.supportsDarkInterface ?? NSNull()
            result["supportsDifferentiateWithoutColorAlone"] = attrs.supportsDifferentiateWithoutColorAlone ?? NSNull()
            result["supportsLargerText"] = attrs.supportsLargerText ?? NSNull()
            result["supportsReducedMotion"] = attrs.supportsReducedMotion ?? NSNull()
            result["supportsSufficientContrast"] = attrs.supportsSufficientContrast ?? NSNull()
            result["supportsVoiceControl"] = attrs.supportsVoiceControl ?? NSNull()
            result["supportsVoiceover"] = attrs.supportsVoiceover ?? NSNull()
        }

        return result
    }
}

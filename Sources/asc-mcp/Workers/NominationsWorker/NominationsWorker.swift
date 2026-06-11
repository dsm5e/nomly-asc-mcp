import Foundation
import MCP

/// NominationsWorker manages App Store nominations — submitting an app for editorial
/// featuring on the App Store (app launch, app enhancements, or new content).
public final class NominationsWorker: Sendable {
    let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Get list of available tools
    public func getTools() async -> [Tool] {
        return [
            listNominationsTool(),
            getNominationTool(),
            createNominationTool(),
            updateNominationTool(),
            deleteNominationTool()
        ]
    }

    /// Handle tool calls (for WorkerManager routing)
    public func handleTool(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        switch params.name {
        case "nominations_list":
            return try await listNominations(params)
        case "nominations_get":
            return try await getNomination(params)
        case "nominations_create":
            return try await createNomination(params)
        case "nominations_update":
            return try await updateNomination(params)
        case "nominations_delete":
            return try await deleteNomination(params)
        default:
            throw MCPError.methodNotFound("Unknown tool: \(params.name)")
        }
    }
}

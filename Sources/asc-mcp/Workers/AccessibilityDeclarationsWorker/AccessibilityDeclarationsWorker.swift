import Foundation
import MCP

/// AccessibilityDeclarationsWorker manages Accessibility Nutrition Labels — declaring
/// which accessibility features an app supports per device family, shown on the
/// App Store product page.
public final class AccessibilityDeclarationsWorker: Sendable {
    let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Get list of available tools
    public func getTools() async -> [Tool] {
        return [
            listAccessibilityDeclarationsTool(),
            getAccessibilityDeclarationTool(),
            createAccessibilityDeclarationTool(),
            updateAccessibilityDeclarationTool(),
            deleteAccessibilityDeclarationTool()
        ]
    }

    /// Handle tool calls (for WorkerManager routing)
    public func handleTool(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        switch params.name {
        case "accessibility_list":
            return try await listAccessibilityDeclarations(params)
        case "accessibility_get":
            return try await getAccessibilityDeclaration(params)
        case "accessibility_create":
            return try await createAccessibilityDeclaration(params)
        case "accessibility_update":
            return try await updateAccessibilityDeclaration(params)
        case "accessibility_delete":
            return try await deleteAccessibilityDeclaration(params)
        default:
            throw MCPError.methodNotFound("Unknown tool: \(params.name)")
        }
    }
}

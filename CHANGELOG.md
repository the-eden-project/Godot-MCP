# Changelog

## v1.0.0 - Initial Implementation

### Added

#### Godot Addon
- Created new `godot_mcp` addon in place of the old `mcp_integration`
- Implemented bidirectional WebSocket server for communication with the MCP server
- Added command handler system to route and process incoming commands
- Created UI panel for controlling the WebSocket server and viewing logs
- Added utility classes for working with nodes, resources, and scripts

#### MCP Server
- Implemented FastMCP-based server for communication with Claude via MCP protocol
- Created robust WebSocket client to connect to the Godot addon
- Defined comprehensive tool set for manipulating Godot projects:
  - Node tools: create, delete, update properties, list nodes
  - Script tools: create, edit, retrieve scripts
  - Scene tools: save, open, get information about scenes
  - Project tools: get project information, create resources

### Technical Improvements
- **Bidirectional Communication**: Implemented WebSocket-based bidirectional communication to allow Claude to send commands to Godot
- **Structured Command System**: All operations follow a consistent command/response pattern
- **Improved Error Handling**: Comprehensive error reporting and handling in both components
- **Modern TypeScript Implementation**: Used TypeScript with Zod schema validation
- **Clean Separation of Concerns**: Godot-specific logic in the addon, MCP protocol in the server

### Architecture
- The Godot addon hosts a WebSocket server that exposes Godot functionality
- The MCP server connects to the Godot WebSocket server and exposes a structured API to Claude
- Command pattern used for all operations with consistent validation and error handling
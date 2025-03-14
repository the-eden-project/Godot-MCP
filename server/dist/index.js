"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fastmcp_1 = require("fastmcp");
const node_tools_1 = require("./tools/node_tools");
const script_tools_1 = require("./tools/script_tools");
const scene_tools_1 = require("./tools/scene_tools");
const godot_connection_1 = require("./utils/godot_connection");
/**
 * Main entry point for the Godot MCP server
 */
async function main() {
    console.log('Starting Godot MCP server...');
    // Create FastMCP instance
    const server = new fastmcp_1.FastMCP({
        name: 'GodotMCP',
        version: '1.0.0',
    });
    // Register all tools
    [...node_tools_1.nodeTools, ...script_tools_1.scriptTools, ...scene_tools_1.sceneTools].forEach(tool => {
        server.addTool(tool);
    });
    // Try to connect to Godot
    try {
        const godot = (0, godot_connection_1.getGodotConnection)();
        await godot.connect();
        console.log('Successfully connected to Godot WebSocket server');
    }
    catch (error) {
        const err = error;
        console.warn(`Could not connect to Godot: ${err.message}`);
        console.warn('Will retry connection when commands are executed');
    }
    // Start the server
    server.start({
        transportType: 'stdio',
    });
    console.log('Godot MCP server started');
    // Handle cleanup
    const cleanup = () => {
        console.log('Shutting down Godot MCP server...');
        const godot = (0, godot_connection_1.getGodotConnection)();
        godot.disconnect();
        process.exit(0);
    };
    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
}
// Start the server
main().catch(error => {
    console.error('Failed to start Godot MCP server:', error);
    process.exit(1);
});
//# sourceMappingURL=index.js.map
import { FastMCP } from 'fastmcp';
import { nodeTools } from './tools/node_tools';
import { scriptTools } from './tools/script_tools';
import { sceneTools } from './tools/scene_tools';
import { getGodotConnection } from './utils/godot_connection';

/**
 * Main entry point for the Godot MCP server
 */
async function main() {
  console.log('Starting Godot MCP server...');

  // Create FastMCP instance
  const server = new FastMCP({
    name: 'GodotMCP',
    version: '1.0.0',
  });

  // Register all tools
  [...nodeTools, ...scriptTools, ...sceneTools].forEach(tool => {
    server.addTool(tool);
  });

  // Try to connect to Godot
  try {
    const godot = getGodotConnection();
    await godot.connect();
    console.log('Successfully connected to Godot WebSocket server');
  } catch (error) {
    const err = error as Error;
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
    const godot = getGodotConnection();
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

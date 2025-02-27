# Godot MCP Script Integration

This project provides an integration between Godot and the Model Context Protocol (MCP). It allows you to access the currently open script in the Godot editor via an MCP server, which can then be used by Claude or other MCP clients.

## Project Structure

- `server/`: The TypeScript MCP server implementation
- `addons/mcp_integration/`: The Godot editor plugin (ready to use in this project)

## Setting Up the MCP Server

1. Navigate to the server directory:
   ```bash
   cd /Users/Shared/Godot/godot-mcp/server
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the server:
   ```bash
   npm run build
   ```

4. When used with Claude Desktop, you don't need to manually run the server - it will be started automatically. For manual testing, you can run:
   ```bash
   npm run start     # For HTTP mode
   npm run stdio     # For stdio mode
   ```

## Using the Godot Plugin

The plugin is already installed in the correct location in this project. To use it:

1. Open this Godot project
2. Go to Project > Project Settings > Plugins
3. Enable the "MCP Script Integration" plugin

## Connecting to Claude Desktop

Configure Claude Desktop to connect to the MCP server:

1. Create or edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "godot-script-server": {
         "command": "node",
         "args": [
           "/Users/Shared/Godot/godot-mcp/server/dist/index.js"
         ],
         "env": {
           "MCP_TRANSPORT": "stdio"
         }
       }
     }
   }
   ```

2. Restart Claude Desktop

## Using the Integration

1. Start Godot and open this project
2. Enable the plugin in Project Settings if not already enabled
3. Edit scripts in Godot
4. In Claude Desktop, you can now access the current script through MCP

## Available MCP Resources and Tools

### Resources:
- `godot://script/current` - The currently open script in the Godot editor

### Tools:
- `update-current-script` - Updates info about the currently open script
- `list-project-scripts` - Lists all script files in a project directory
- `read-script` - Reads the content of a specific script

## Troubleshooting

### EADDRINUSE Error

If you see an error like `Error: listen EADDRINUSE: address already in use :::3000` in the logs:

1. This is normal when Claude Desktop launches two instances of the server
2. The server will continue to function properly using stdio communication
3. Only the HTTP server portion will fail, which isn't needed for Claude Desktop

If you need to run the HTTP server manually:

1. Make sure no other services are using port 3000
2. Alternatively, specify a different port: `PORT=3001 npm run start`

### Other Common Issues

- If the plugin isn't seeing script changes, try restarting Godot
- Check the Godot console for any error messages from the plugin
- Check the server's console output for any connection issues

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
# Godot MCP Script Integration

This project provides an integration between Godot and the Model Context Protocol (MCP). It allows you to access the currently open script in the Godot editor via an MCP server, which can then be used by Claude or other MCP clients.

## Project Structure

- `server/`: The TypeScript MCP server implementation
- `godot-plugin/`: The Godot editor plugin

## Setting Up the MCP Server

1. Navigate to the server directory:
   ```bash
   cd /Users/Shared/Godot/godot-mcp/server
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build and run the server:
   ```bash
   npm run dev
   ```

   This will start the server on http://localhost:3000.

## Setting Up the Godot Plugin

1. Copy the plugin to your Godot project:
   ```bash
   cp -r /Users/Shared/Godot/godot-mcp/godot-plugin/addons/mcp_integration /path/to/your-godot-project/addons/
   ```

2. Enable the plugin in Godot:
   - Open your Godot project
   - Go to Project > Project Settings > Plugins
   - Enable the "MCP Script Integration" plugin

## Connecting to Claude Desktop

1. Configure Claude Desktop to connect to the MCP server:
   - Create or edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "godot-script-server": {
         "command": "node",
         "args": [
           "/Users/Shared/Godot/godot-mcp/server/dist/index.js"
         ]
       }
     }
   }
   ```

2. Restart Claude Desktop

## Using the Integration

1. Start the MCP server if running separately
2. Start Godot and open your project
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

- If the plugin isn't seeing script changes, try restarting Godot
- Check the Godot console for any error messages from the plugin
- Make sure the server is running before opening Godot
- Check the server's console output for any connection issues
# Godot MCP Installation Guide

This guide will walk you through the process of installing and configuring the Godot MCP integration. The integration consists of two main components:

1. **Godot MCP Addon**: A plugin for the Godot editor
2. **MCP Server**: A Node.js server that connects Claude to Godot

## Prerequisites

Before you begin, ensure you have the following:

- Godot Engine 4.x
- Node.js 16.x or higher
- npm or yarn
- Git (optional, for cloning repositories)
- Claude Desktop (for testing)

## Installing the Godot MCP Addon

### Method 1: Via Godot Asset Library

1. Open your Godot project
2. Go to the AssetLib tab in the Godot editor
3. Search for "Godot MCP"
4. Click "Download" and then "Install"
5. In the installation dialog, click "Install"
6. Navigate to Project → Project Settings → Plugins
7. Enable the "Godot MCP" plugin

### Method 2: Manual Installation

1. Download the latest release of the Godot MCP addon from [GitHub](https://github.com/example/godot-mcp)
2. Extract the contents of the `addons` folder to your project's `addons` folder
3. If your project doesn't have an `addons` folder, create one
4. Open your Godot project
5. Navigate to Project → Project Settings → Plugins
6. Enable the "Godot MCP" plugin

## Installing the MCP Server

### Method 1: Using npm

```bash
# Install globally
npm install -g godot-mcp-server

# Or install in a specific directory
mkdir godot-mcp
cd godot-mcp
npm install godot-mcp-server
```

### Method 2: From Source

```bash
# Clone the repository
git clone https://github.com/example/godot-mcp-server.git

# Navigate to the directory
cd godot-mcp-server

# Install dependencies
npm install

# Build the server
npm run build
```

## Configuration

### Configuring the Godot Addon

1. Open your Godot project
2. Look for the "MCP" panel in the right dock area
3. Configure the WebSocket server:
   - Port: 9080 (default)
   - Enable "Allow Remote" if you want to connect from another machine
   - Select log level (Info is recommended)
4. Click "Start Server" to begin accepting connections

### Configuring the MCP Server

1. Create a `.env` file in the MCP server directory:

```
# Godot WebSocket connection
GODOT_WS_URL=ws://localhost:9080

# Server settings
LOG_LEVEL=info
COMMAND_TIMEOUT=10000

# SSE transport settings (if using SSE)
SSE_PORT=8080
SSE_ENDPOINT=/sse
```

2. Adjust settings as needed:
   - `GODOT_WS_URL`: WebSocket URL for connecting to Godot
   - `LOG_LEVEL`: Verbosity of logging (debug, info, warn, error)
   - `COMMAND_TIMEOUT`: Timeout for commands in milliseconds

## Configuring Claude Desktop

To use Godot MCP with Claude Desktop, you need to configure Claude to use the MCP server:

1. Open Claude Desktop
2. Click on the Claude menu in the menu bar
3. Select "Settings"
4. Click on "Developer" in the left sidebar
5. Click "Edit Config"
6. Add the Godot MCP server to the configuration:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "godot-mcp-server",
      "args": []
    }
  }
}
```

If you installed from source:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["/path/to/godot-mcp-server/dist/index.js"]
    }
  }
}
```

7. Save the file and restart Claude Desktop

## Verifying the Installation

### Testing the Godot Addon

1. Open your Godot project
2. Start the MCP server from the MCP panel
3. Check that the status indicator turns green
4. Look for a message in the log view saying "Server started on port 9080"

### Testing the MCP Server

1. Start the MCP server:

```bash
# If installed globally
godot-mcp-server

# If installed in a directory
npx godot-mcp-server

# If installed from source
npm start
```

2. Look for output indicating the server is running
3. Verify it can connect to Godot by looking for a message like "Connected to Godot WebSocket server"

### Testing with Claude

1. Start the Godot editor with your project
2. Start the MCP server in the Godot editor
3. Open Claude Desktop
4. Look for the MCP icon in the Claude interface
5. Try a simple command like "Create a Sprite2D node named PlayerSprite"

## Troubleshooting

### Godot Addon Issues

1. **Plugin doesn't appear in Plugins list**
   - Ensure the plugin is in the correct directory (`addons/godot_mcp`)
   - Check that the plugin structure is correct
   - Restart Godot

2. **WebSocket server won't start**
   - Check if the port is already in use
   - Look for error messages in the Godot console
   - Try restarting Godot
   - Check if your OS has any firewall blocking the connection

3. **UI panel doesn't appear**
   - Ensure the plugin is enabled
   - Check the bottom panel and right dock for the MCP panel
   - Try restarting Godot

### MCP Server Issues

1. **Server won't start**
   - Check if Node.js is properly installed
   - Ensure all dependencies are installed
   - Look for error messages in the console
   - Check if the correct paths are used in commands

2. **Cannot connect to Godot**
   - Verify the Godot WebSocket server is running
   - Check the WebSocket URL in the configuration
   - Ensure no firewalls are blocking the connection
   - Try using localhost instead of 127.0.0.1 or vice versa

3. **Commands failing**
   - Check the command format and parameters
   - Look for detailed error messages in the logs
   - Verify that paths exist and are correctly formatted

### Claude Integration Issues

1. **Claude doesn't recognize the MCP server**
   - Check the Claude Desktop configuration
   - Ensure the MCP server is properly registered
   - Look for errors in the Claude Desktop logs
   - Restart Claude Desktop

2. **Commands not executing**
   - Verify both the Godot WebSocket server and MCP server are running
   - Check logs for any error messages
   - Ensure commands are properly formatted

## Next Steps

Now that you have successfully installed and configured the Godot MCP integration, you can:

1. Explore the available [commands](./command-reference.md)
2. Learn about the [architecture](./architecture.md)
3. Try some [example workflows](./examples.md)
4. Customize and extend the functionality

## Support

If you encounter any issues or have questions:

- Check the [documentation](./README.md)
- Review the [troubleshooting](#troubleshooting) section
- Submit an issue on GitHub
- Reach out to the community on Discord
# Godot MCP Architecture Proposal

## Current Implementation Analysis

Based on your description, the critical flaw in your current Godot MCP implementation is that it follows a one-way communication pattern where:

- The Godot addon **pushes** data to the MCP server
- But doesn't provide a mechanism for the MCP server to **send commands** to Godot

This severely limits the ability of Claude to interact with Godot, as it can only receive information but cannot initiate actions or make changes to your Godot projects.

## Blender MCP Architecture Review

The Blender MCP implementation provides an excellent reference architecture:

1. **Bidirectional Communication**: Uses a socket server within Blender that can both receive commands and send responses
2. **Command Execution Engine**: Routes incoming JSON commands to appropriate Blender API calls
3. **Tool Definitions**: Exposes Blender operations as tools that Claude can use via MCP
4. **Clean Separation of Concerns**: 
   - Blender addon handles Blender-specific functionality
   - MCP server handles Claude communication and MCP protocol implementation

This architecture enables Claude to have full control over Blender through natural language, which is precisely what you need for Godot.

## FastMCP TypeScript Library Benefits

FastMCP provides several features that would benefit your Godot MCP implementation:

- **Simplified Tool Definitions**: Easy way to define tools with validation via Zod
- **Session Management**: Handles client sessions and authentication
- **Robust Error Handling**: Built-in error types and logging
- **Communication Options**: Supports both stdio and SSE transports
- **Progress Reporting**: For long-running operations
- **Sampling Support**: For complex AI interactions

## Proposed Godot MCP Architecture

I propose a bidirectional architecture similar to the Blender implementation, but with modern WebSocket communication:

### 1. Godot Addon Component (`godot_mcp_addon/`)

```
godot_mcp_addon/
├── addons/
│   └── godot_mcp/
│       ├── plugin.cfg
│       ├── godot_mcp.gd        # Main plugin file
│       ├── websocket_server.gd # WebSocket server implementation
│       ├── command_handler.gd  # Command routing and execution
│       ├── ui/                 # UI components
│       │   ├── mcp_panel.gd
│       │   └── mcp_panel.tscn
│       └── utils/              # Utility functions
│           ├── node_utils.gd
│           ├── resource_utils.gd
│           └── script_utils.gd
```

#### WebSocket Server (`websocket_server.gd`)

```gdscript
class_name MCPWebSocketServer
extends Node

signal command_received(command)
signal client_connected
signal client_disconnected

var _server := WebSocketServer.new()
var _clients := []
var _port := 9080

func _ready() -> void:
    _server.connect("client_connected", self, "_on_client_connected")
    _server.connect("client_disconnected", self, "_on_client_disconnected")
    _server.connect("data_received", self, "_on_data_received")

func start() -> Error:
    var err := _server.listen(_port)
    print("MCP WebSocket server started on port %d" % _port)
    return err

func stop() -> void:
    _server.stop()
    print("MCP WebSocket server stopped")

func _process(_delta: float) -> void:
    if _server.is_listening():
        _server.poll()

func send_response(client_id: int, response: Dictionary) -> void:
    var data := JSON.print(response).to_utf8()
    _server.get_peer(client_id).put_packet(data)

func _on_client_connected(id: int, _protocol: String) -> void:
    _clients.append(id)
    emit_signal("client_connected")
    print("MCP client connected: %d" % id)

func _on_client_disconnected(id: int, _was_clean: bool) -> void:
    _clients.erase(id)
    emit_signal("client_disconnected")
    print("MCP client disconnected: %d" % id)

func _on_data_received(id: int) -> void:
    var data: PackedByteArray = _server.get_peer(id).get_packet()
    var text := data.get_string_from_utf8()
    
    var json := JSON.new()
    var error := json.parse(text)
    
    if error == OK:
        var command = json.get_data()
        print("Received command: %s" % command)
        emit_signal("command_received", id, command)
    else:
        print("Error parsing JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
```

#### Command Handler (`command_handler.gd`)

```gdscript
class_name MCPCommandHandler
extends Node

var _websocket_server: MCPWebSocketServer

func _ready() -> void:
    _websocket_server = get_parent().get_node("WebSocketServer")
    _websocket_server.connect("command_received", self, "_handle_command")

func _handle_command(client_id: int, command: Dictionary) -> void:
    var command_type: String = command.get("type", "")
    var params: Dictionary = command.get("params", {})
    
    match command_type:
        "create_node":
            _create_node(client_id, params)
        "delete_node":
            _delete_node(client_id, params)
        "update_node":
            _update_node(client_id, params)
        "list_nodes":
            _list_nodes(client_id, params)
        "create_script":
            _create_script(client_id, params)
        "edit_script":
            _edit_script(client_id, params)
        "get_script":
            _get_script(client_id, params)
        "create_resource":
            _create_resource(client_id, params)
        "save_scene":
            _save_scene(client_id, params)
        "open_scene":
            _open_scene(client_id, params)
        _:
            _send_error(client_id, "Unknown command: %s" % command_type)

# Command implementation methods
func _create_node(client_id: int, params: Dictionary) -> void:
    var parent_path = params.get("parent_path", "/root")
    var node_type = params.get("node_type", "Node")
    var node_name = params.get("node_name", "NewNode")
    
    var parent = get_node(parent_path)
    if not parent:
        return _send_error(client_id, "Parent node not found: %s" % parent_path)
    
    var node = ClassDB.instance(node_type)
    if not node:
        return _send_error(client_id, "Failed to create node of type: %s" % node_type)
    
    node.name = node_name
    parent.add_child(node)
    node.owner = get_tree().edited_scene_root
    
    _send_success(client_id, {
        "node_path": node.get_path()
    })

# More command implementations...

func _send_success(client_id: int, result: Dictionary) -> void:
    _websocket_server.send_response(client_id, {
        "status": "success",
        "result": result
    })

func _send_error(client_id: int, message: String) -> void:
    _websocket_server.send_response(client_id, {
        "status": "error",
        "message": message
    })
```

### 2. MCP Server Component (TypeScript with FastMCP)

```
mcp_server/
├── src/
│   ├── index.ts              # Entry point
│   ├── godot_connection.ts   # Godot connection manager
│   ├── tools/                # Tool definitions
│   │   ├── node_tools.ts     # Node manipulation tools
│   │   ├── script_tools.ts   # Script manipulation tools
│   │   └── resource_tools.ts # Resource manipulation tools
│   └── utils/                # Utility functions
│       ├── websocket.ts
│       └── error_handler.ts
├── package.json
└── tsconfig.json
```

#### Godot Connection Manager (`godot_connection.ts`)

```typescript
import WebSocket from 'ws';

export interface GodotResponse {
  status: 'success' | 'error';
  result?: any;
  message?: string;
}

export class GodotConnection {
  private ws: WebSocket | null = null;
  private connected = false;
  private commandQueue: Map<string, { 
    resolve: (value: any) => void;
    reject: (reason: any) => void;
    timeout: NodeJS.Timeout;
  }> = new Map();
  private commandId = 0;

  constructor(private url: string = 'ws://localhost:9080') {}

  async connect(): Promise<void> {
    if (this.connected) return;

    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url);

      this.ws.on('open', () => {
        this.connected = true;
        console.log('Connected to Godot WebSocket server');
        resolve();
      });

      this.ws.on('message', (data: Buffer) => {
        try {
          const response: GodotResponse = JSON.parse(data.toString());
          console.log('Received response:', response);
          
          // Handle command responses
          if ('commandId' in response) {
            const commandId = response.commandId as string;
            const pendingCommand = this.commandQueue.get(commandId);
            
            if (pendingCommand) {
              clearTimeout(pendingCommand.timeout);
              this.commandQueue.delete(commandId);
              
              if (response.status === 'success') {
                pendingCommand.resolve(response.result);
              } else {
                pendingCommand.reject(new Error(response.message || 'Unknown error'));
              }
            }
          }
        } catch (error) {
          console.error('Error parsing response:', error);
        }
      });

      this.ws.on('error', (error) => {
        console.error('WebSocket error:', error);
        reject(error);
      });

      this.ws.on('close', () => {
        console.log('Disconnected from Godot WebSocket server');
        this.connected = false;
      });
    });
  }

  async sendCommand<T = any>(type: string, params: Record<string, any> = {}): Promise<T> {
    if (!this.ws || !this.connected) {
      await this.connect();
    }

    return new Promise((resolve, reject) => {
      const commandId = `cmd_${this.commandId++}`;
      
      const command = {
        type,
        params,
        commandId
      };

      // Set timeout for command
      const timeout = setTimeout(() => {
        if (this.commandQueue.has(commandId)) {
          this.commandQueue.delete(commandId);
          reject(new Error(`Command timed out: ${type}`));
        }
      }, 10000); // 10 second timeout

      // Store the promise resolvers
      this.commandQueue.set(commandId, {
        resolve,
        reject,
        timeout
      });

      // Send the command
      this.ws!.send(JSON.stringify(command));
    });
  }

  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
      this.connected = false;
    }
  }
}

// Singleton instance
let connectionInstance: GodotConnection | null = null;

export function getGodotConnection(): GodotConnection {
  if (!connectionInstance) {
    connectionInstance = new GodotConnection();
  }
  return connectionInstance;
}
```

#### MCP Server Implementation (`index.ts`)

```typescript
import { FastMCP } from 'fastmcp';
import { z } from 'zod';
import { getGodotConnection } from './godot_connection';

// Create MCP server
const server = new FastMCP({
  name: 'GodotMCP',
  version: '1.0.0',
});

// Node Tools
server.addTool({
  name: 'create_node',
  description: 'Create a new node in the scene tree',
  parameters: z.object({
    parent_path: z.string().describe('Path to the parent node'),
    node_type: z.string().describe('Type of node to create'),
    node_name: z.string().describe('Name for the new node'),
  }),
  execute: async (args) => {
    const godot = getGodotConnection();
    try {
      const result = await godot.sendCommand('create_node', args);
      return `Created node ${args.node_name} of type ${args.node_type} at ${result.node_path}`;
    } catch (error) {
      throw new Error(`Failed to create node: ${error.message}`);
    }
  },
});

server.addTool({
  name: 'delete_node',
  description: 'Delete a node from the scene tree',
  parameters: z.object({
    node_path: z.string().describe('Path to the node to delete'),
  }),
  execute: async (args) => {
    const godot = getGodotConnection();
    try {
      await godot.sendCommand('delete_node', args);
      return `Deleted node at ${args.node_path}`;
    } catch (error) {
      throw new Error(`Failed to delete node: ${error.message}`);
    }
  },
});

// Script Tools
server.addTool({
  name: 'create_script',
  description: 'Create a new GDScript file',
  parameters: z.object({
    node_path: z.string().optional().describe('Path to attach script to (optional)'),
    script_path: z.string().describe('Path to save the script'),
    content: z.string().describe('Script content'),
  }),
  execute: async (args) => {
    const godot = getGodotConnection();
    try {
      const result = await godot.sendCommand('create_script', args);
      return `Created script at ${result.script_path}`;
    } catch (error) {
      throw new Error(`Failed to create script: ${error.message}`);
    }
  },
});

server.addTool({
  name: 'edit_script',
  description: 'Edit an existing GDScript file',
  parameters: z.object({
    script_path: z.string().describe('Path to the script to edit'),
    content: z.string().describe('New script content'),
  }),
  execute: async (args) => {
    const godot = getGodotConnection();
    try {
      await godot.sendCommand('edit_script', args);
      return `Updated script at ${args.script_path}`;
    } catch (error) {
      throw new Error(`Failed to update script: ${error.message}`);
    }
  },
});

// Scene Tools
server.addTool({
  name: 'save_scene',
  description: 'Save the current scene',
  parameters: z.object({
    path: z.string().optional().describe('Path to save the scene (optional, uses current path if not provided)'),
  }),
  execute: async (args) => {
    const godot = getGodotConnection();
    try {
      const result = await godot.sendCommand('save_scene', args);
      return `Saved scene to ${result.scene_path}`;
    } catch (error) {
      throw new Error(`Failed to save scene: ${error.message}`);
    }
  },
});

// Start the server
server.start({
  transportType: 'stdio',
});

// Handle cleanup
process.on('SIGINT', () => {
  console.log('Shutting down GodotMCP server...');
  const godot = getGodotConnection();
  godot.disconnect();
  process.exit(0);
});
```

## Implementation Plan

Here's a step-by-step plan to implement this architecture:

1. **Create the Godot Addon**:
   - Implement the WebSocket server in Godot
   - Develop command handling infrastructure
   - Create a UI panel for server control
   - Implement node, resource, and script manipulation utilities

2. **Develop the MCP Server**:
   - Set up the FastMCP-based server
   - Implement the Godot WebSocket connection manager
   - Define tools for various Godot operations
   - Add error handling and logging

3. **Testing and Refinement**:
   - Test basic commands like node creation and script editing
   - Verify bidirectional communication
   - Test with Claude to ensure proper interaction

## Key Improvements Over Current Implementation

1. **Bidirectional Communication**: The WebSocket server allows Claude to send commands to Godot via the MCP server
2. **Comprehensive Tool Set**: Clear definition of operations Claude can perform
3. **Robust Error Handling**: Proper error propagation and response formatting
4. **Clean Separation of Concerns**:
   - Godot addon handles Godot-specific operations
   - MCP server handles Claude communication using FastMCP

## Next Steps

1. Review this proposal and provide feedback
2. Set up the development environment for both components
3. Begin implementation of the Godot WebSocket server
4. Develop the MCP server with FastMCP
5. Create documentation for the commands and tools available to Claude

Would you like me to expand on any specific part of this architecture proposal? Or would you like to see more detailed code for any particular component?
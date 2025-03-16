I'll check both files first to ensure we have an accurate implementation plan.

Let me check the directory structure first:



Let's look at the main server file:





Let's look at the tool structure:





Let's check one of the tool files to understand the structure:








Let's look at the command handler in the addon:








Let me check one of the command processors:







Let's look at the node commands:










Based on the code I've reviewed, let me provide a more focused implementation plan for the `execute_editor_script` tool:

## Refined Implementation Plan for `execute_editor_script` MCP Tool

### 1. Add a New Tool to the MCP Server

First, we need to create a new tool file in the server's tools directory to handle the editor script execution:

**File: `/Users/Shared/Godot/godot-mcp/server/src/tools/editor_tools.ts`**

```typescript
import { z } from 'zod';
import { getGodotConnection } from '../utils/godot_connection.js';
import { MCPTool } from '../utils/types.js';

interface ExecuteEditorScriptParams {
  code: string;
}

export const editorTools: MCPTool[] = [
  {
    name: 'execute_editor_script',
    description: 'Executes arbitrary GDScript code in the Godot editor',
    parameters: z.object({
      code: z.string()
        .describe('GDScript code to execute in the editor context'),
    }),
    execute: async ({ code }: ExecuteEditorScriptParams): Promise<string> => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('execute_editor_script', { code });
        
        // Format output for display
        let outputText = 'Script executed successfully';
        
        if (result.output && Array.isArray(result.output) && result.output.length > 0) {
          outputText += '\n\nOutput:\n' + result.output.join('\n');
        }
        
        if (result.result) {
          outputText += '\n\nResult:\n' + JSON.stringify(result.result, null, 2);
        }
        
        return outputText;
      } catch (error) {
        throw new Error(`Script execution failed: ${(error as Error).message}`);
      }
    },
  },
];
```

### 2. Update the Main Server File

Next, update the main server file to include our new tool:

**File: `/Users/Shared/Godot/godot-mcp/server/src/index.ts`**

```typescript
// Import the new editor tools
import { editorTools } from './tools/editor_tools.js';

// In the main() function, update the tools registration:
// Register all tools
[...nodeTools, ...scriptTools, ...sceneTools, ...editorTools].forEach(tool => {
  server.addTool(tool);
});
```

### 3. Create a Command Processor in the Godot Addon

Now, we need to create a new command processor to handle the editor script execution in Godot:

**File: `/Users/Shared/Godot/godot-mcp/addons/godot_mcp/commands/editor_script_commands.gd`**

```gdscript
@tool
class_name MCPEditorScriptCommands
extends MCPBaseCommandProcessor

func process_command(client_id: int, command_type: String, params: Dictionary, command_id: String) -> bool:
	match command_type:
		"execute_editor_script":
			_execute_editor_script(client_id, params, command_id)
			return true
	return false  # Command not handled

func _execute_editor_script(client_id: int, params: Dictionary, command_id: String) -> void:
	var code = params.get("code", "")
	
	# Validation
	if code.is_empty():
		return _send_error(client_id, "Code cannot be empty", command_id)
	
	# Create a temporary script node to execute the code
	var script_node = Node.new()
	add_child(script_node)
	
	# Create a temporary script
	var script = GDScript.new()
	
	# Capture output with a custom print function
	var output = []
	var original_print = print
	print = func(text): output.append(str(text))
	
	var error_message = ""
	var execution_result = null
	
	# Prepare script with error handling
	var script_content = """
@tool
extends Node

# Variable to store the result
var result = null

func _ready():
	var scene = get_tree().edited_scene_root
	
	# Execute the provided code in a try-catch block
	try:
		# USER CODE START
{user_code}
		# USER CODE END
		
	except (error):
		printerr("Error executing script: " + str(error))
		get_parent()._on_script_error(str(error))
"""
	
	# Indent the user code
	var indented_code = ""
	var lines = code.split("\n")
	for line in lines:
		indented_code += "\t\t" + line + "\n"
	
	script_content = script_content.replace("{user_code}", indented_code)
	script.source_code = script_content
	script.reload()
	
	# Create a method to handle script errors
	script_node._on_script_error = func(error): 
		error_message = error
	
	# Assign the script to the node
	script_node.set_script(script)
	
	# Wait a frame to ensure the script has executed
	await get_tree().process_frame
	
	# Clean up
	if script_node.has_method("result"):
		execution_result = script_node.result
	
	remove_child(script_node)
	script_node.queue_free()
	
	# Restore original print function
	print = original_print
	
	# Build the response
	var result_data = {
		"success": error_message.is_empty(),
		"output": output
	}
	
	if not error_message.is_empty():
		result_data["error"] = error_message
	elif execution_result != null:
		result_data["result"] = execution_result
	
	_send_success(client_id, result_data, command_id)
```

### 4. Update the Command Handler

Finally, update the command handler to register our new script processor:

**File: `/Users/Shared/Godot/godot-mcp/addons/godot_mcp/command_handler.gd`**

```gdscript
func _initialize_command_processors():
	# Create and add all command processors
	var node_commands = MCPNodeCommands.new()
	var script_commands = MCPScriptCommands.new()
	var scene_commands = MCPSceneCommands.new() 
	var project_commands = MCPProjectCommands.new()
	var editor_commands = MCPEditorCommands.new()
	var editor_script_commands = MCPEditorScriptCommands.new()  # Add our new processor
	
	# Set server reference for all processors
	node_commands._websocket_server = _websocket_server
	script_commands._websocket_server = _websocket_server
	scene_commands._websocket_server = _websocket_server
	project_commands._websocket_server = _websocket_server
	editor_commands._websocket_server = _websocket_server
	editor_script_commands._websocket_server = _websocket_server  # Set server reference
	
	# Add them to our processor list
	_command_processors.append(node_commands)
	_command_processors.append(script_commands)
	_command_processors.append(scene_commands)
	_command_processors.append(project_commands)
	_command_processors.append(editor_commands)
	_command_processors.append(editor_script_commands)  # Add to processor list
	
	# Add them as children for proper lifecycle management
	add_child(node_commands)
	add_child(script_commands)
	add_child(scene_commands)
	add_child(project_commands)
	add_child(editor_commands)
	add_child(editor_script_commands)  # Add as child
```

### Usage Examples

Once implemented, here are some usage examples:

#### 1. Setting a Collision Shape

```typescript
// Call the execute_editor_script tool
const result = await mcp.callTool("execute_editor_script", {
  code: `
    # Create a BoxShape3D for the ground
    var ground_shape = BoxShape3D.new()
    ground_shape.size = Vector3(20.0, 1.0, 20.0)
    
    # Get the node
    var node = get_tree().edited_scene_root.get_node("Ground/GroundCollision")
    
    # Assign the shape
    node.shape = ground_shape
    
    # Store the result
    result = "BoxShape3D assigned successfully"
  `
});
```

#### 2. Creating a Complex Scene

```typescript
const result = await mcp.callTool("execute_editor_script", {
  code: `
    # Create a new scene
    var scene = EditorInterface.get_edited_scene_root()
    
    # Add multiple objects with collision shapes
    for i in range(5):
      # Create a platform
      var platform = StaticBody3D.new()
      platform.name = "Platform" + str(i)
      scene.add_child(platform)
      platform.owner = scene
      
      # Position it
      platform.position = Vector3(i * 3.0, i * 1.5, 0)
      
      # Add collision
      var collision = CollisionShape3D.new()
      collision.name = "Collision"
      platform.add_child(collision)
      collision.owner = scene
      
      # Create and assign shape
      var shape = BoxShape3D.new()
      shape.size = Vector3(2.0, 0.5, 2.0)
      collision.shape = shape
      
      # Add mesh
      var mesh_instance = MeshInstance3D.new()
      mesh_instance.name = "Mesh"
      platform.add_child(mesh_instance)
      mesh_instance.owner = scene
      
      # Create and assign mesh
      var box_mesh = BoxMesh.new()
      box_mesh.size = Vector3(2.0, 0.5, 2.0)
      mesh_instance.mesh = box_mesh
    
    # Store the result
    result = "Created 5 platforms with collision shapes"
  `
});
```

This implementation provides a powerful, flexible way to execute arbitrary GDScript code in the Godot editor context, making it possible to perform complex operations that would be difficult to implement with specific API methods. The LLM can generate appropriate code for each task, giving you maximum flexibility without needing to implement every possible Godot feature in your MCP server.
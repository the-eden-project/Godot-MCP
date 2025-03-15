Let me examine the existing code in your MCP server and command handler to provide more targeted recommendations.

Based on my review of your codebase, I now have a much clearer understanding of the current implementation and can provide targeted recommendations to better align with the MCP specification. Here's my comprehensive analysis:

# Current Implementation Analysis

## MCP Server Structure

Your current Godot MCP server is well-structured but focused entirely on Tools:

1. You're using FastMCP for your server implementation
2. Your tools are organized into categories:
   - `nodeTools`: Node CRUD operations
   - `scriptTools`: Script operations
   - `sceneTools`: Scene and resource operations
3. All tools follow a consistent pattern of defining parameters with Zod and providing an execute function
4. The server communicates with Godot through a WebSocket connection

## Missing MCP Features

Based on the specification, your implementation is currently missing:

1. **Resources**: No implementation of the resources capability
2. **Prompts**: No implementation of the prompts capability
3. **Root Management**: No implementation of roots capability
4. **Sampling**: No implementation of sampling capability

# Recommended Enhancements

Here are my recommendations to better align your implementation with the MCP specification:

## 1. Add Resource Support

The absence of resources is a significant gap in your MCP implementation. Resources provide context data to LLMs without executing actions.

### Implementation Strategy:

```typescript
// src/resources/scene_resources.ts
import { ResourceDefinition, ResourceTemplateDefinition } from 'fastmcp';
import { getGodotConnection } from '../utils/godot_connection.js';

export const sceneListResource: ResourceDefinition = {
  uri: 'godot://scenes/list',
  name: 'Scene List',
  description: 'List of all scenes in the project',
  async load() {
    const godot = getGodotConnection();
    try {
      // Create a new command to list all scene files
      const result = await godot.sendCommand('list_project_files', { 
        extensions: ['.tscn'] 
      });
      return { text: JSON.stringify(result.files, null, 2) };
    } catch (error) {
      console.error('Failed to load scene list:', error);
      return { text: 'Error loading scene list' };
    }
  }
};

export const sceneStructureTemplate: ResourceTemplateDefinition = {
  uriTemplate: 'godot://scenes/{scenePath}',
  name: 'Scene Structure',
  description: 'Node structure of a scene file',
  async load({ scenePath }) {
    const godot = getGodotConnection();
    try {
      // Create a new command to get scene structure
      const result = await godot.sendCommand('get_scene_structure', { path: scenePath });
      return { text: JSON.stringify(result.structure, null, 2) };
    } catch (error) {
      console.error('Failed to load scene structure:', error);
      return { text: 'Error loading scene structure' };
    }
  }
};
```

Then register these in the main server file:

```typescript
// src/index.ts (updated)
import { sceneListResource, sceneStructureTemplate } from './resources/scene_resources.js';
import { scriptResourceTemplate } from './resources/script_resources.js';

// Add resources to server
server.addResource(sceneListResource);
server.addResourceTemplate(sceneStructureTemplate);
server.addResourceTemplate(scriptResourceTemplate);
```

### Required Godot Commands:

You would need to add new command handlers in `command_handler.gd`:

```gdscript
# Add to _handle_command function in command_handler.gd
match command_type:
    # ... existing commands
    
    # Resource-related commands
    "list_project_files":
        _list_project_files(client_id, params, command_id)
    "get_scene_structure":
        _get_scene_structure(client_id, params, command_id)
    "get_script_metadata":
        _get_script_metadata(client_id, params, command_id)

# New command implementations
func _list_project_files(client_id: int, params: Dictionary, command_id: String) -> void:
    var extensions = params.get("extensions", [])
    var files = []
    
    # Get all files with the specified extensions
    var dir = DirAccess.open("res://")
    _scan_directory(dir, "", extensions, files)
    
    _send_success(client_id, {
        "files": files
    }, command_id)

func _scan_directory(dir: DirAccess, path: String, extensions: Array, files: Array) -> void:
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if dir.current_is_dir():
            var subdir = DirAccess.open("res://" + path + file_name)
            if subdir:
                _scan_directory(subdir, path + file_name + "/", extensions, files)
        else:
            var file_path = path + file_name
            var has_valid_extension = extensions.is_empty()
            
            for ext in extensions:
                if file_name.ends_with(ext):
                    has_valid_extension = true
                    break
            
            if has_valid_extension:
                files.append("res://" + file_path)
        
        file_name = dir.get_next()
```

## 2. Add Prompt Support

Prompts would help users interact with Godot more effectively through standardized templates.

### Implementation Strategy:

```typescript
// src/prompts/scene_prompts.ts
import { PromptDefinition } from 'fastmcp';

export const createScenePrompt: PromptDefinition = {
  name: 'create-scene',
  description: 'Create a new scene with specified elements',
  arguments: [
    {
      name: 'sceneType',
      description: '2D or 3D scene',
      required: true,
      enum: ['2D', '3D', 'UI']
    },
    {
      name: 'rootNodeName',
      description: 'Name for the root node',
      required: true
    },
    {
      name: 'elements',
      description: 'Description of elements to add to the scene',
      required: true
    }
  ],
  async load(args) {
    return `
Please create a new ${args.sceneType} scene with a root node named "${args.rootNodeName}". 
The scene should include the following elements:

${args.elements}

Please make sure the scene is properly structured and include any necessary scripts 
to implement the functionality described.
`;
  }
};

export const refactorScriptPrompt: PromptDefinition = {
  name: 'refactor-script',
  description: 'Get guidance on refactoring a GDScript',
  arguments: [
    {
      name: 'scriptPath',
      description: 'Path to the script to refactor',
      required: true
    },
    {
      name: 'improvements',
      description: 'Specific improvements to focus on',
      required: true
    }
  ],
  async load(args) {
    return `
Please help me refactor the GDScript at ${args.scriptPath}. 
I would like you to focus on the following improvements:

${args.improvements}

First analyze the code to understand its structure and purpose, then suggest 
specific refactoring changes that would improve it while maintaining its functionality.
`;
  }
};
```

Then register these in the main file:

```typescript
// src/index.ts (updated)
import { createScenePrompt, refactorScriptPrompt } from './prompts/scene_prompts.js';

// Add prompts to server
server.addPrompt(createScenePrompt);
server.addPrompt(refactorScriptPrompt);
```

## 3. Update the Godot Command Handler

To support the new resource and prompt features, you'll need to extend your command handler:

```gdscript
# Add to command_handler.gd

func _get_scene_structure(client_id: int, params: Dictionary, command_id: String) -> void:
    var path = params.get("path", "")
    
    # Validation
    if path.is_empty():
        return _send_error(client_id, "Scene path cannot be empty", command_id)
    
    if not path.begins_with("res://"):
        path = "res://" + path
    
    if not FileAccess.file_exists(path):
        return _send_error(client_id, "Scene file not found: " + path, command_id)
    
    # Load the scene to analyze its structure
    var packed_scene = load(path)
    if not packed_scene:
        return _send_error(client_id, "Failed to load scene: " + path, command_id)
    
    # Create a temporary instance to analyze
    var scene_instance = packed_scene.instantiate()
    if not scene_instance:
        return _send_error(client_id, "Failed to instantiate scene: " + path, command_id)
    
    # Get the structure
    var structure = _get_node_structure(scene_instance)
    
    # Clean up
    scene_instance.free()
    
    _send_success(client_id, {
        "scene_path": path,
        "structure": structure
    }, command_id)

func _get_node_structure(node: Node) -> Dictionary:
    var structure = {
        "name": node.name,
        "type": node.get_class(),
        "properties": {},
        "children": []
    }
    
    # Get key properties
    for prop in ["position", "scale", "rotation", "visible"]:
        if prop in node:
            structure.properties[prop] = node.get(prop)
    
    # Add script information if available
    var script = node.get_script()
    if script:
        structure.properties["script"] = script.resource_path
    
    # Process children
    for child in node.get_children():
        structure.children.append(_get_node_structure(child))
    
    return structure
```

## 4. Main Server Implementation Updates

Finally, update your main server file to include all the MCP capabilities:

```typescript
// src/index.ts
import { FastMCP } from 'fastmcp';
import { nodeTools } from './tools/node_tools.js';
import { scriptTools } from './tools/script_tools.js';
import { sceneTools } from './tools/scene_tools.js';
import { getGodotConnection } from './utils/godot_connection.js';

// Import resources and prompts
import { sceneListResource, sceneStructureTemplate } from './resources/scene_resources.js';
import { scriptResourceTemplate } from './resources/script_resources.js';
import { createScenePrompt, refactorScriptPrompt } from './prompts/scene_prompts.js';

/**
 * Main entry point for the Godot MCP server
 */
async function main() {
  console.error('Starting Godot MCP server...');

  // Create FastMCP instance
  const server = new FastMCP({
    name: 'GodotMCP',
    version: '1.0.0',
  });

  // Register all tools
  [...nodeTools, ...scriptTools, ...sceneTools].forEach(tool => {
    server.addTool(tool);
  });

  // Register resources
  server.addResource(sceneListResource);
  server.addResourceTemplate(sceneStructureTemplate);
  server.addResourceTemplate(scriptResourceTemplate);

  // Register prompts
  server.addPrompt(createScenePrompt);
  server.addPrompt(refactorScriptPrompt);

  // Try to connect to Godot
  try {
    const godot = getGodotConnection();
    await godot.connect();
    console.error('Successfully connected to Godot WebSocket server');
  } catch (error) {
    const err = error as Error;
    console.warn(`Could not connect to Godot: ${err.message}`);
    console.warn('Will retry connection when commands are executed');
  }

  // Start the server
  server.start({
    transportType: 'stdio',
  });

  console.error('Godot MCP server started');

  // Handle cleanup
  const cleanup = () => {
    console.error('Shutting down Godot MCP server...');
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
```

# Implementation Plan

Here's a phased approach to implementing these changes:

## Phase 1: Resources
1. Create commands in the Godot addon to support resource retrieval
2. Implement resource definitions in the MCP server
3. Test scene and script resources with Claude

## Phase 2: Prompts
1. Implement prompt definitions for common Godot workflows
2. Test prompts with Claude to ensure they produce helpful results
3. Refine prompt templates based on feedback

## Phase 3: Additional Features
1. Implement subscription support for resources
2. Add resource change notifications
3. Consider implementing sampling capabilities for advanced agentic workflows

# Development Tips

1. **Incremental approach**: Implement one capability at a time
2. **Test with Claude**: Use Claude to test each feature as you implement it
3. **Focus on usefulness**: Prioritize resources and prompts that will be most helpful
4. **Documentation**: Document your new features properly for future reference

By implementing these recommendations, your Godot MCP server will more fully align with the MCP specification and provide a richer and more powerful integration between Claude and Godot.
# Godot MCP Command Reference

This document provides a comprehensive reference for all commands supported by the Godot MCP integration. Each command is detailed with its parameters, response format, and examples.

## Table of Contents

- [Node Commands](#node-commands)
- [Script Commands](#script-commands)
- [Resource Commands](#resource-commands)
- [Scene Commands](#scene-commands)
- [Project Commands](#project-commands)
- [Response Formats](#response-formats)

## Node Commands

Commands for manipulating nodes in the Godot scene tree.

### `create_node`

Creates a new node in the scene tree.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `parent_path` | string | Path to the parent node | Yes |
| `node_type` | string | Type of node to create | Yes |
| `node_name` | string | Name for the new node | Yes |
| `properties` | object | Initial property values | No |

#### Example

```json
{
  "type": "create_node",
  "params": {
    "parent_path": "/root/Main",
    "node_type": "Sprite2D",
    "node_name": "PlayerSprite",
    "properties": {
      "texture": "res://assets/player.png",
      "position": [100, 100],
      "scale": [2, 2]
    }
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "node_path": "/root/Main/PlayerSprite"
  }
}
```

### `delete_node`

Removes a node from the scene tree.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `node_path` | string | Path to the node to delete | Yes |

#### Example

```json
{
  "type": "delete_node",
  "params": {
    "node_path": "/root/Main/PlayerSprite"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "deleted": true
  }
}
```

### `update_node`

Updates properties of an existing node.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `node_path` | string | Path to the node to update | Yes |
| `properties` | object | Properties to update | Yes |

#### Example

```json
{
  "type": "update_node",
  "params": {
    "node_path": "/root/Main/PlayerSprite",
    "properties": {
      "position": [200, 150],
      "modulate": [1, 0, 0, 1]
    }
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "updated": true,
    "updated_properties": ["position", "modulate"]
  }
}
```

### `list_nodes`

Lists nodes in the scene tree.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `parent_path` | string | Path to the parent node | Yes |
| `recursive` | boolean | Whether to list nodes recursively | No |
| `include_properties` | boolean | Whether to include node properties | No |
| `property_filter` | array | List of properties to include (if include_properties is true) | No |

#### Example

```json
{
  "type": "list_nodes",
  "params": {
    "parent_path": "/root/Main",
    "recursive": true,
    "include_properties": true,
    "property_filter": ["position", "scale", "visible"]
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "nodes": [
      {
        "name": "PlayerSprite",
        "type": "Sprite2D",
        "path": "/root/Main/PlayerSprite",
        "properties": {
          "position": [200, 150],
          "scale": [2, 2],
          "visible": true
        },
        "children": []
      },
      {
        "name": "UI",
        "type": "CanvasLayer",
        "path": "/root/Main/UI",
        "properties": {
          "visible": true
        },
        "children": [
          {
            "name": "ScoreLabel",
            "type": "Label",
            "path": "/root/Main/UI/ScoreLabel",
            "properties": {
              "position": [10, 10],
              "visible": true
            },
            "children": []
          }
        ]
      }
    ]
  }
}
```

### `get_node_info`

Gets detailed information about a specific node.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `node_path` | string | Path to the node | Yes |
| `include_properties` | boolean | Whether to include all properties | No |
| `include_signals` | boolean | Whether to include connected signals | No |
| `include_methods` | boolean | Whether to include available methods | No |

#### Example

```json
{
  "type": "get_node_info",
  "params": {
    "node_path": "/root/Main/PlayerSprite",
    "include_properties": true,
    "include_signals": true,
    "include_methods": false
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "name": "PlayerSprite",
    "type": "Sprite2D",
    "path": "/root/Main/PlayerSprite",
    "properties": {
      "position": [200, 150],
      "scale": [2, 2],
      "texture": "res://assets/player.png",
      "visible": true,
      "modulate": [1, 0, 0, 1]
    },
    "signals": [
      {
        "name": "texture_changed",
        "connections": []
      }
    ]
  }
}
```

## Script Commands

Commands for working with GDScript files.

### `create_script`

Creates a new GDScript file.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `script_path` | string | Path to save the script | Yes |
| `content` | string | Script content | Yes |
| `node_path` | string | Path to node to attach script to | No |

#### Example

```json
{
  "type": "create_script",
  "params": {
    "script_path": "res://scripts/player.gd",
    "content": "extends Sprite2D\n\nfunc _ready():\n\tprint('Player ready')\n",
    "node_path": "/root/Main/PlayerSprite"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "script_path": "res://scripts/player.gd",
    "attached_to": "/root/Main/PlayerSprite"
  }
}
```

### `edit_script`

Modifies an existing script.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `script_path` | string | Path to the script to edit | Yes |
| `content` | string | New script content | Yes |

#### Example

```json
{
  "type": "edit_script",
  "params": {
    "script_path": "res://scripts/player.gd",
    "content": "extends Sprite2D\n\nfunc _ready():\n\tprint('Player ready')\n\nfunc _process(delta):\n\tposition.x += 100 * delta\n"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "script_path": "res://scripts/player.gd",
    "updated": true
  }
}
```

### `get_script`

Retrieves a script's content.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `script_path` | string | Path to the script | Yes |

#### Example

```json
{
  "type": "get_script",
  "params": {
    "script_path": "res://scripts/player.gd"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "script_path": "res://scripts/player.gd",
    "content": "extends Sprite2D\n\nfunc _ready():\n\tprint('Player ready')\n\nfunc _process(delta):\n\tposition.x += 100 * delta\n"
  }
}
```

### `list_scripts`

Lists scripts in a directory.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `directory` | string | Directory to search | Yes |
| `recursive` | boolean | Whether to search recursively | No |

#### Example

```json
{
  "type": "list_scripts",
  "params": {
    "directory": "res://scripts",
    "recursive": true
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "scripts": [
      {
        "path": "res://scripts/player.gd",
        "size": 120,
        "modified": "2023-10-15T14:30:00Z"
      },
      {
        "path": "res://scripts/enemy.gd",
        "size": 250,
        "modified": "2023-10-14T12:15:00Z"
      }
    ]
  }
}
```

## Resource Commands

Commands for working with Godot resources.

### `create_resource`

Creates a new resource.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `resource_type` | string | Type of resource to create | Yes |
| `resource_path` | string | Path to save the resource | Yes |
| `properties` | object | Initial property values | No |

#### Example

```json
{
  "type": "create_resource",
  "params": {
    "resource_type": "ShaderMaterial",
    "resource_path": "res://materials/glow.tres",
    "properties": {
      "shader_parameter/glow_color": [1, 0.5, 0, 1],
      "shader_parameter/glow_intensity": 2.0
    }
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "resource_path": "res://materials/glow.tres",
    "resource_type": "ShaderMaterial"
  }
}
```

### `update_resource`

Updates an existing resource.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `resource_path` | string | Path to the resource | Yes |
| `properties` | object | Properties to update | Yes |

#### Example

```json
{
  "type": "update_resource",
  "params": {
    "resource_path": "res://materials/glow.tres",
    "properties": {
      "shader_parameter/glow_intensity": 3.0
    }
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "resource_path": "res://materials/glow.tres",
    "updated_properties": ["shader_parameter/glow_intensity"]
  }
}
```

### `list_resources`

Lists resources in a directory.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `directory` | string | Directory to search | Yes |
| `recursive` | boolean | Whether to search recursively | No |
| `type_filter` | string | Filter by resource type | No |

#### Example

```json
{
  "type": "list_resources",
  "params": {
    "directory": "res://materials",
    "recursive": false,
    "type_filter": "ShaderMaterial"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "resources": [
      {
        "path": "res://materials/glow.tres",
        "type": "ShaderMaterial"
      },
      {
        "path": "res://materials/water.tres",
        "type": "ShaderMaterial"
      }
    ]
  }
}
```

## Scene Commands

Commands for managing Godot scenes.

### `save_scene`

Saves the current scene.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `path` | string | Path to save the scene (optional) | No |

#### Example

```json
{
  "type": "save_scene",
  "params": {
    "path": "res://scenes/level1.tscn"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "scene_path": "res://scenes/level1.tscn"
  }
}
```

### `open_scene`

Opens a scene.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `path` | string | Path to the scene | Yes |

#### Example

```json
{
  "type": "open_scene",
  "params": {
    "path": "res://scenes/level2.tscn"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "scene_path": "res://scenes/level2.tscn"
  }
}
```

### `list_scenes`

Lists scene files in a directory.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `directory` | string | Directory to search | Yes |
| `recursive` | boolean | Whether to search recursively | No |

#### Example

```json
{
  "type": "list_scenes",
  "params": {
    "directory": "res://scenes",
    "recursive": true
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "scenes": [
      {
        "path": "res://scenes/level1.tscn",
        "size": 2048,
        "modified": "2023-10-15T14:30:00Z"
      },
      {
        "path": "res://scenes/level2.tscn",
        "size": 3072,
        "modified": "2023-10-16T10:15:00Z"
      }
    ]
  }
}
```

## Project Commands

Commands for managing the Godot project.

### `list_files`

Lists files in a directory.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `directory` | string | Directory to search | Yes |
| `recursive` | boolean | Whether to search recursively | No |
| `pattern` | string | File pattern to match | No |

#### Example

```json
{
  "type": "list_files",
  "params": {
    "directory": "res://",
    "recursive": false,
    "pattern": "*.png"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "files": [
      {
        "path": "res://icon.png",
        "type": "file",
        "size": 4096
      },
      {
        "path": "res://logo.png",
        "type": "file",
        "size": 8192
      }
    ]
  }
}
```

### `get_project_settings`

Retrieves project settings.

#### Parameters

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `category` | string | Settings category to retrieve | No |

#### Example

```json
{
  "type": "get_project_settings",
  "params": {
    "category": "rendering"
  }
}
```

#### Response

```json
{
  "status": "success",
  "result": {
    "settings": {
      "rendering/environment/default_environment": "res://default_env.tres",
      "rendering/quality/driver/driver_name": "GLES2"
    }
  }
}
```

## Response Formats

All commands return responses in one of the following formats:

### Success Response

```json
{
  "status": "success",
  "result": {
    // Command-specific result data
  },
  "commandId": "cmd_123"  // Same ID as in the command
}
```

### Error Response

```json
{
  "status": "error",
  "message": "Detailed error message",
  "commandId": "cmd_123"  // Same ID as in the command
}
```

### Common Error Messages

| Error Message | Description |
|---------------|-------------|
| "Node not found" | The specified node path does not exist |
| "Invalid node type" | The specified node type is not valid |
| "Access to path denied" | Cannot access the specified path |
| "File already exists" | Cannot create a file that already exists |
| "Invalid resource type" | The specified resource type is not valid |
| "Scene not saved" | Failed to save the scene |
| "Command timed out" | The command took too long to execute |
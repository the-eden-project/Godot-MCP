import { z } from 'zod';
import { getGodotConnection } from '../utils/godot_connection';

/**
 * Definition for scene tools - operations that manipulate Godot scenes
 */
export const sceneTools = [
  {
    name: 'save_scene',
    description: 'Save the current scene to disk',
    parameters: z.object({
      path: z.string().optional()
        .describe('Path where the scene will be saved (e.g. "res://scenes/main.tscn"). If not provided, uses current scene path.'),
    }),
    execute: async ({ path }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('save_scene', { path });
        return `Saved scene to ${result.scene_path}`;
      } catch (error) {
        throw new Error(`Failed to save scene: ${error.message}`);
      }
    },
  },

  {
    name: 'open_scene',
    description: 'Open a scene in the editor',
    parameters: z.object({
      path: z.string()
        .describe('Path to the scene file to open (e.g. "res://scenes/main.tscn")'),
    }),
    execute: async ({ path }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('open_scene', { path });
        return `Opened scene at ${result.scene_path}`;
      } catch (error) {
        throw new Error(`Failed to open scene: ${error.message}`);
      }
    },
  },

  {
    name: 'get_current_scene',
    description: 'Get information about the currently open scene',
    parameters: z.object({}),
    execute: async () => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('get_current_scene', {});
        
        return `Current scene: ${result.scene_path}\nRoot node: ${result.root_node_name} (${result.root_node_type})`;
      } catch (error) {
        throw new Error(`Failed to get current scene: ${error.message}`);
      }
    },
  },

  {
    name: 'get_project_info',
    description: 'Get information about the current Godot project',
    parameters: z.object({}),
    execute: async () => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('get_project_info', {});
        
        const godotVersion = `${result.godot_version.major}.${result.godot_version.minor}.${result.godot_version.patch}`;
        
        let output = `Project Name: ${result.project_name}\n`;
        output += `Project Version: ${result.project_version}\n`;
        output += `Godot Version: ${godotVersion}\n`;
        
        if (result.current_scene) {
          output += `Current Scene: ${result.current_scene}`;
        } else {
          output += "No scene is currently open";
        }
        
        return output;
      } catch (error) {
        throw new Error(`Failed to get project info: ${error.message}`);
      }
    },
  },

  {
    name: 'create_resource',
    description: 'Create a new resource in the project',
    parameters: z.object({
      resource_type: z.string()
        .describe('Type of resource to create (e.g. "ImageTexture", "AudioStreamMP3", "StyleBoxFlat")'),
      resource_path: z.string()
        .describe('Path where the resource will be saved (e.g. "res://resources/style.tres")'),
      properties: z.record(z.any()).optional()
        .describe('Dictionary of property values to set on the resource'),
    }),
    execute: async ({ resource_type, resource_path, properties = {} }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('create_resource', {
          resource_type,
          resource_path,
          properties,
        });
        
        return `Created ${resource_type} resource at ${result.resource_path}`;
      } catch (error) {
        throw new Error(`Failed to create resource: ${error.message}`);
      }
    },
  },
];
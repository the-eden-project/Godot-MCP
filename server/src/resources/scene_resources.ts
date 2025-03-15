import { Resource, ResourceTemplate } from 'fastmcp';
import { getGodotConnection } from '../utils/godot_connection.js';
import { z } from 'zod';

/**
 * Resource that provides a list of all scenes in the project
 */
export const sceneListResource: Resource = {
  uri: 'godot/scenes',
  name: 'Godot Scene List',
  mimeType: 'application/json',
  async load() {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to list all scenes
      const result = await godot.sendCommand('list_project_files', {
        extensions: ['.tscn', '.scn']
      });
      
      if (result && result.files) {
        return {
          text: JSON.stringify({
            scenes: result.files,
            count: result.files.length
          })
        };
      } else {
        return {
          text: JSON.stringify({
            scenes: [],
            count: 0
          })
        };
      }
    } catch (error) {
      console.error('Error fetching scene list:', error);
      throw error;
    }
  }
};

/**
 * Resource template that provides detailed information about a specific scene
 */
export const sceneStructureTemplate: ResourceTemplate = {
  uriTemplate: 'godot/scene/{path}',
  name: 'Godot Scene Structure',
  mimeType: 'application/json',
  arguments: [
    {
      name: 'path',
      description: 'Path to the scene file (e.g., "my_scene.tscn")',
      required: true,
      complete: async (value) => {
        // Try to get matching scenes for autocompletion
        try {
          const godot = getGodotConnection();
          const result = await godot.sendCommand('list_project_files', {
            extensions: ['.tscn', '.scn']
          });
          
          if (result && result.files) {
            const matchingFiles = result.files.filter((file: string) => 
              file.includes(value) && (file.endsWith('.tscn') || file.endsWith('.scn'))
            ).map((file: string) => {
              // Strip res:// prefix for cleaner display
              return file.replace('res://', '');
            });
            
            return {
              values: matchingFiles
            };
          }
        } catch (error) {
          console.error('Error completing scene paths:', error);
        }
        
        return {
          values: []
        };
      }
    }
  ],
  async load(params: { path: string }) {
    const godot = getGodotConnection();
    let scenePath = params.path;
    
    // Make sure path starts with res://
    if (!scenePath.startsWith('res://')) {
      scenePath = `res://${scenePath}`;
    }
    
    try {
      // Call a command on the Godot side to get scene structure
      const result = await godot.sendCommand('get_scene_structure', {
        path: scenePath
      });
      
      return {
        text: JSON.stringify(result)
      };
    } catch (error) {
      console.error('Error fetching scene structure:', error);
      throw error;
    }
  }
};
import { getGodotConnection } from '../utils/godot_connection.js';
import { z } from 'zod';

/**
 * Resource that provides a list of all scenes in the project
 */
export const sceneListResource = {
  name: 'godot/scenes',
  description: 'List of all scene files in the Godot project',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to list all scenes
      const result = await godot.sendCommand('list_project_files', {
        extensions: ['.tscn', '.scn']
      });
      
      if (result && result.files) {
        return {
          scenes: result.files,
          count: result.files.length
        };
      } else {
        return {
          scenes: [],
          count: 0
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
export const sceneStructureTemplate = {
  name: 'godot/scene/:path',
  description: 'Detailed structure of a Godot scene',
  parameters: z.object({
    path: z.string().describe('Path to the scene file (e.g., "res://my_scene.tscn")')
  }),
  fetch: async (params: { path: string }) => {
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
      
      return result;
    } catch (error) {
      console.error('Error fetching scene structure:', error);
      throw error;
    }
  }
};
import { getGodotConnection } from '../utils/godot_connection.js';
import { z } from 'zod';

/**
 * Resource template that provides the content of a specific script
 */
export const scriptResourceTemplate = {
  name: 'godot/script/:path',
  description: 'Content and metadata of a Godot script file',
  parameters: z.object({
    path: z.string().describe('Path to the script file (e.g., "res://player.gd")')
  }),
  fetch: async (params: { path: string }) => {
    const godot = getGodotConnection();
    let scriptPath = params.path;
    
    // Make sure path starts with res://
    if (!scriptPath.startsWith('res://')) {
      scriptPath = `res://${scriptPath}`;
    }
    
    try {
      // Call a command on the Godot side to get script content
      const result = await godot.sendCommand('get_script', {
        path: scriptPath
      });
      
      return {
        content: result.content,
        path: result.script_path,
        language: scriptPath.endsWith('.gd') ? 'gdscript' : 
                 scriptPath.endsWith('.cs') ? 'csharp' : 'unknown'
      };
    } catch (error) {
      console.error('Error fetching script content:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides a list of all scripts in the project
 */
export const scriptListResource = {
  name: 'godot/scripts',
  description: 'List of all script files in the Godot project',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to list all scripts
      const result = await godot.sendCommand('list_project_files', {
        extensions: ['.gd', '.cs']
      });
      
      if (result && result.files) {
        return {
          scripts: result.files,
          count: result.files.length,
          gdscripts: result.files.filter((f: string) => f.endsWith('.gd')),
          csharp_scripts: result.files.filter((f: string) => f.endsWith('.cs'))
        };
      } else {
        return {
          scripts: [],
          count: 0,
          gdscripts: [],
          csharp_scripts: []
        };
      }
    } catch (error) {
      console.error('Error fetching script list:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides metadata for a specific script, including classes and methods
 */
export const scriptMetadataTemplate = {
  name: 'godot/script/metadata/:path',
  description: 'Metadata about a Godot script including classes, methods, and properties',
  parameters: z.object({
    path: z.string().describe('Path to the script file (e.g., "res://player.gd")')
  }),
  fetch: async (params: { path: string }) => {
    const godot = getGodotConnection();
    let scriptPath = params.path;
    
    // Make sure path starts with res://
    if (!scriptPath.startsWith('res://')) {
      scriptPath = `res://${scriptPath}`;
    }
    
    try {
      // Call a command on the Godot side to get script metadata
      const result = await godot.sendCommand('get_script_metadata', {
        path: scriptPath
      });
      
      return result;
    } catch (error) {
      console.error('Error fetching script metadata:', error);
      throw error;
    }
  }
};
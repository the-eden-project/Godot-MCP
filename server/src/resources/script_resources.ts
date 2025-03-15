import { Resource, ResourceTemplate } from 'fastmcp';
import { getGodotConnection } from '../utils/godot_connection.js';
import { z } from 'zod';

/**
 * Resource template that provides the content of a specific script
 */
export const scriptResourceTemplate: ResourceTemplate = {
  uriTemplate: 'godot/script/{path}',
  name: 'Godot Script Content',
  mimeType: 'text/plain',
  arguments: [
    {
      name: 'path',
      description: 'Path to the script file (e.g., "player.gd")',
      required: true,
      complete: async (value) => {
        // Try to get matching scripts for autocompletion
        try {
          const godot = getGodotConnection();
          const result = await godot.sendCommand('list_project_files', {
            extensions: ['.gd', '.cs']
          });
          
          if (result && result.files) {
            const matchingFiles = result.files.filter((file: string) => 
              file.includes(value) && (file.endsWith('.gd') || file.endsWith('.cs'))
            ).map((file: string) => {
              // Strip res:// prefix for cleaner display
              return file.replace('res://', '');
            });
            
            return {
              values: matchingFiles
            };
          }
        } catch (error) {
          console.error('Error completing script paths:', error);
        }
        
        return {
          values: []
        };
      }
    }
  ],
  async load(params: { path: string }) {
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
        text: result.content,
        metadata: {
          path: result.script_path,
          language: scriptPath.endsWith('.gd') ? 'gdscript' : 
                   scriptPath.endsWith('.cs') ? 'csharp' : 'unknown'
        }
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
export const scriptListResource: Resource = {
  uri: 'godot/scripts',
  name: 'Godot Script List',
  mimeType: 'application/json',
  async load() {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to list all scripts
      const result = await godot.sendCommand('list_project_files', {
        extensions: ['.gd', '.cs']
      });
      
      if (result && result.files) {
        return {
          text: JSON.stringify({
            scripts: result.files,
            count: result.files.length,
            gdscripts: result.files.filter((f: string) => f.endsWith('.gd')),
            csharp_scripts: result.files.filter((f: string) => f.endsWith('.cs'))
          })
        };
      } else {
        return {
          text: JSON.stringify({
            scripts: [],
            count: 0,
            gdscripts: [],
            csharp_scripts: []
          })
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
export const scriptMetadataTemplate: ResourceTemplate = {
  uriTemplate: 'godot/script/metadata/{path}',
  name: 'Godot Script Metadata',
  mimeType: 'application/json',
  arguments: [
    {
      name: 'path',
      description: 'Path to the script file (e.g., "player.gd")',
      required: true,
      complete: async (value) => {
        // Use the same completion logic as scriptResourceTemplate
        try {
          const godot = getGodotConnection();
          const result = await godot.sendCommand('list_project_files', {
            extensions: ['.gd', '.cs']
          });
          
          if (result && result.files) {
            const matchingFiles = result.files.filter((file: string) => 
              file.includes(value) && (file.endsWith('.gd') || file.endsWith('.cs'))
            ).map((file: string) => {
              return file.replace('res://', '');
            });
            
            return {
              values: matchingFiles
            };
          }
        } catch (error) {
          console.error('Error completing script paths:', error);
        }
        
        return {
          values: []
        };
      }
    }
  ],
  async load(params: { path: string }) {
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
      
      return {
        text: JSON.stringify(result)
      };
    } catch (error) {
      console.error('Error fetching script metadata:', error);
      throw error;
    }
  }
};
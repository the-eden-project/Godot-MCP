import { getGodotConnection } from '../utils/godot_connection.js';

/**
 * Resource that provides information about the current state of the Godot editor
 */
export const editorStateResource = {
  name: 'godot/editor/state',
  description: 'Current state of the Godot editor including open scenes and selected nodes',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get editor state
      const result = await godot.sendCommand('get_editor_state');
      
      return result;
    } catch (error) {
      console.error('Error fetching editor state:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides information about the currently selected node
 */
export const selectedNodeResource = {
  name: 'godot/editor/selected_node',
  description: 'Details about the currently selected node in the Godot editor',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get selected node
      const result = await godot.sendCommand('get_selected_node');
      
      return result;
    } catch (error) {
      console.error('Error fetching selected node:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides information about the currently edited script
 */
export const currentScriptResource = {
  name: 'godot/editor/current_script',
  description: 'Content and metadata of the currently open script in the Godot editor',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get current script
      const result = await godot.sendCommand('get_current_script');
      
      // If we got a script path, return script content and metadata
      if (result && result.script_path) {
        return {
          path: result.script_path,
          content: result.content,
          language: result.script_path.endsWith('.gd') ? 'gdscript' : 
                   result.script_path.endsWith('.cs') ? 'csharp' : 'unknown'
        };
      } else {
        return {
          path: null,
          content: null,
          language: null
        };
      }
    } catch (error) {
      console.error('Error fetching current script:', error);
      throw error;
    }
  }
};
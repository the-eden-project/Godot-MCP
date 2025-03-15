import { getGodotConnection } from '../utils/godot_connection.js';

/**
 * Resource that provides information about the Godot project structure
 */
export const projectStructureResource = {
  name: 'godot/project/structure',
  description: 'Overview of the Godot project structure including directories and file counts',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get project structure
      const result = await godot.sendCommand('get_project_structure');
      
      return result;
    } catch (error) {
      console.error('Error fetching project structure:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides project settings
 */
export const projectSettingsResource = {
  name: 'godot/project/settings',
  description: 'Godot project settings including rendering, physics, input mappings, etc.',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get project settings
      const result = await godot.sendCommand('get_project_settings');
      
      return result;
    } catch (error) {
      console.error('Error fetching project settings:', error);
      throw error;
    }
  }
};

/**
 * Resource that provides a list of all project resources
 */
export const projectResourcesResource = {
  name: 'godot/project/resources',
  description: 'List of all resources in the Godot project by type',
  fetch: async () => {
    const godot = getGodotConnection();
    
    try {
      // Call a command on the Godot side to get a list of all resources
      const result = await godot.sendCommand('list_project_resources');
      
      return result;
    } catch (error) {
      console.error('Error fetching project resources:', error);
      throw error;
    }
  }
};
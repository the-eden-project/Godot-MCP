import { z } from 'zod';
import { getGodotConnection } from '../utils/godot_connection';

/**
 * Definition for node tools - operations that manipulate nodes in the scene tree
 */
export const nodeTools = [
  {
    name: 'create_node',
    description: 'Create a new node in the Godot scene tree',
    parameters: z.object({
      parent_path: z.string()
        .describe('Path to the parent node where the new node will be created (e.g. "/root", "/root/MainScene")'),
      node_type: z.string()
        .describe('Type of node to create (e.g. "Node2D", "Sprite2D", "Label")'),
      node_name: z.string()
        .describe('Name for the new node'),
    }),
    execute: async ({ parent_path, node_type, node_name }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('create_node', {
          parent_path,
          node_type,
          node_name,
        });
        
        return `Created ${node_type} node named "${node_name}" at ${result.node_path}`;
      } catch (error) {
        throw new Error(`Failed to create node: ${error.message}`);
      }
    },
  },

  {
    name: 'delete_node',
    description: 'Delete a node from the Godot scene tree',
    parameters: z.object({
      node_path: z.string()
        .describe('Path to the node to delete (e.g. "/root/MainScene/Player")'),
    }),
    execute: async ({ node_path }) => {
      const godot = getGodotConnection();
      
      try {
        await godot.sendCommand('delete_node', { node_path });
        return `Deleted node at ${node_path}`;
      } catch (error) {
        throw new Error(`Failed to delete node: ${error.message}`);
      }
    },
  },

  {
    name: 'update_node_property',
    description: 'Update a property of a node in the Godot scene tree',
    parameters: z.object({
      node_path: z.string()
        .describe('Path to the node to update (e.g. "/root/MainScene/Player")'),
      property: z.string()
        .describe('Name of the property to update (e.g. "position", "text", "modulate")'),
      value: z.any()
        .describe('New value for the property'),
    }),
    execute: async ({ node_path, property, value }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('update_node_property', {
          node_path,
          property,
          value,
        });
        
        return `Updated property "${property}" of node at ${node_path} to ${JSON.stringify(value)}`;
      } catch (error) {
        throw new Error(`Failed to update node property: ${error.message}`);
      }
    },
  },

  {
    name: 'get_node_properties',
    description: 'Get all properties of a node in the Godot scene tree',
    parameters: z.object({
      node_path: z.string()
        .describe('Path to the node to inspect (e.g. "/root/MainScene/Player")'),
    }),
    execute: async ({ node_path }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('get_node_properties', { node_path });
        
        // Format properties for display
        const formattedProperties = Object.entries(result.properties)
          .map(([key, value]) => `${key}: ${JSON.stringify(value)}`)
          .join('\n');
        
        return `Properties of node at ${node_path}:\n\n${formattedProperties}`;
      } catch (error) {
        throw new Error(`Failed to get node properties: ${error.message}`);
      }
    },
  },

  {
    name: 'list_nodes',
    description: 'List all child nodes under a parent node in the Godot scene tree',
    parameters: z.object({
      parent_path: z.string()
        .describe('Path to the parent node (e.g. "/root", "/root/MainScene")'),
    }),
    execute: async ({ parent_path }) => {
      const godot = getGodotConnection();
      
      try {
        const result = await godot.sendCommand('list_nodes', { parent_path });
        
        if (result.children.length === 0) {
          return `No child nodes found under ${parent_path}`;
        }
        
        // Format children for display
        const formattedChildren = result.children
          .map(child => `${child.name} (${child.type}) - ${child.path}`)
          .join('\n');
        
        return `Children of node at ${parent_path}:\n\n${formattedChildren}`;
      } catch (error) {
        throw new Error(`Failed to list nodes: ${error.message}`);
      }
    },
  },
];
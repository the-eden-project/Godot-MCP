@tool
class_name MCPCommandHandler
extends Node

var _websocket_server
var _command_processors = []

func _ready():
	print("Command handler initializing...")
	await get_tree().process_frame
	_websocket_server = get_parent()
	print("WebSocket server reference set: ", _websocket_server)
	
	# Initialize command processors
	_initialize_command_processors()
	
	print("Command handler initialized and ready to process commands")

func _initialize_command_processors():
	# Create and add all command processors
	var node_commands = MCPNodeCommands.new()
	var script_commands = MCPScriptCommands.new()
	var scene_commands = MCPSceneCommands.new() 
	var project_commands = MCPProjectCommands.new()
	var editor_commands = MCPEditorCommands.new()
	
	# Set server reference for all processors
	node_commands._websocket_server = _websocket_server
	script_commands._websocket_server = _websocket_server
	scene_commands._websocket_server = _websocket_server
	project_commands._websocket_server = _websocket_server
	editor_commands._websocket_server = _websocket_server
	
	# Add them to our processor list
	_command_processors.append(node_commands)
	_command_processors.append(script_commands)
	_command_processors.append(scene_commands)
	_command_processors.append(project_commands)
	_command_processors.append(editor_commands)
	
	# Add them as children for proper lifecycle management
	add_child(node_commands)
	add_child(script_commands)
	add_child(scene_commands)
	add_child(project_commands)
	add_child(editor_commands)

func _handle_command(client_id: int, command: Dictionary) -> void:
	var command_type = command.get("type", "")
	var params = command.get("params", {})
	var command_id = command.get("commandId", "")
	
	print("Processing command: %s" % command_type)
	
	# Try each processor until one handles the command
	for processor in _command_processors:
		if processor.process_command(client_id, command_type, params, command_id):
			return
	
	# If no processor handled the command, send an error
	_send_error(client_id, "Unknown command: %s" % command_type, command_id)

# Helper function to access nodes in the editor context
func _get_editor_node(path: String) -> Node:
	var plugin = Engine.get_meta("GodotMCPPlugin")
	if not plugin:
		print("GodotMCPPlugin not found in Engine metadata")
		return null
		
	var editor_interface = plugin.get_editor_interface()
	var edited_scene_root = editor_interface.get_edited_scene_root()
	
	if not edited_scene_root:
		print("No edited scene found")
		return null
		
	# Handle absolute paths
	if path == "/root" or path == "":
		return edited_scene_root
		
	if path.begins_with("/root/"):
		path = path.substr(6)  # Remove "/root/"
	elif path.begins_with("/"):
		path = path.substr(1)  # Remove leading "/"
	
	# Try to find node as child of edited scene root
	return edited_scene_root.get_node_or_null(path)

# Helper function to mark a scene as modified
func _mark_scene_modified() -> void:
	var plugin = Engine.get_meta("GodotMCPPlugin")
	if not plugin:
		print("GodotMCPPlugin not found in Engine metadata")
		return
	
	var editor_interface = plugin.get_editor_interface()
	var edited_scene_root = editor_interface.get_edited_scene_root()
	
	if edited_scene_root:
		# This internally marks the scene as modified in the editor
		editor_interface.mark_scene_as_unsaved()

# Helper function to parse property values from string to proper Godot types
func _parse_property_value(value):
	# Only try to parse strings that look like they could be Godot types
	if typeof(value) == TYPE_STRING and (
		value.begins_with("Vector") or 
		value.begins_with("Transform") or 
		value.begins_with("Rect") or 
		value.begins_with("Color") or
		value.begins_with("Quat") or
		value.begins_with("Basis") or
		value.begins_with("Plane") or
		value.begins_with("AABB") or
		value.begins_with("Projection") or
		value.begins_with("Callable") or
		value.begins_with("Signal") or
		value.begins_with("PackedVector") or
		value.begins_with("PackedString") or
		value.begins_with("PackedFloat") or
		value.begins_with("PackedInt") or
		value.begins_with("PackedColor") or
		value.begins_with("PackedByteArray") or
		value.begins_with("Dictionary") or
		value.begins_with("Array")
	):
		var expression = Expression.new()
		var error = expression.parse(value, [])
		
		if error == OK:
			var result = expression.execute([], null, true)
			if not expression.has_execute_failed():
				print("Successfully parsed %s as %s" % [value, result])
				return result
			else:
				print("Failed to execute expression for: %s" % value)
		else:
			print("Failed to parse expression: %s (Error: %d)" % [value, error])
	
	# Otherwise, return value as is
	return value

# Helper function to access the EditorUndoRedoManager
func _get_undo_redo():
	var plugin = Engine.get_meta("GodotMCPPlugin")
	if not plugin or not plugin.has_method("get_undo_redo"):
		print("Cannot access UndoRedo from plugin")
		return null
		
	return plugin.get_undo_redo()

# Helper functions
func _send_success(client_id: int, result: Dictionary, command_id: String) -> void:
	var response = {
		"status": "success",
		"result": result
	}
	
	if not command_id.is_empty():
		response["commandId"] = command_id
	
	_websocket_server.send_response(client_id, response)

func _send_error(client_id: int, message: String, command_id: String) -> void:
	var response = {
		"status": "error",
		"message": message
	}
	
	if not command_id.is_empty():
		response["commandId"] = command_id
	
	_websocket_server.send_response(client_id, response)
	print("Error: %s" % message)

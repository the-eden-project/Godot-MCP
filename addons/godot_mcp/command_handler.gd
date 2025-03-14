@tool
class_name MCPCommandHandler
extends Node

var _websocket_server: MCPWebSocketServer

func _ready():
	await get_tree().process_frame
	_websocket_server = get_parent()
	_websocket_server.connect("command_received", Callable(self, "_handle_command"))

func _handle_command(client_id: int, command: Dictionary) -> void:
	var command_type = command.get("type", "")
	var params = command.get("params", {})
	var command_id = command.get("commandId", "")
	
	print("Processing command: %s" % command_type)
	
	# Command routing
	match command_type:
		# Node operations
		"create_node":
			_create_node(client_id, params, command_id)
		"delete_node":
			_delete_node(client_id, params, command_id)
		"update_node_property":
			_update_node_property(client_id, params, command_id)
		"get_node_properties":
			_get_node_properties(client_id, params, command_id)
		"list_nodes":
			_list_nodes(client_id, params, command_id)
		
		# Script operations
		"create_script":
			_create_script(client_id, params, command_id)
		"edit_script":
			_edit_script(client_id, params, command_id)
		"get_script":
			_get_script(client_id, params, command_id)
		
		# Scene operations
		"save_scene":
			_save_scene(client_id, params, command_id)
		"open_scene":
			_open_scene(client_id, params, command_id)
		"get_current_scene":
			_get_current_scene(client_id, params, command_id)
		
		# Resource operations
		"create_resource":
			_create_resource(client_id, params, command_id)
		
		# Project operations
		"get_project_info":
			_get_project_info(client_id, params, command_id)
		
		_:
			_send_error(client_id, "Unknown command: %s" % command_type, command_id)

# Node operations
func _create_node(client_id: int, params: Dictionary, command_id: String) -> void:
	var parent_path = params.get("parent_path", "/root")
	var node_type = params.get("node_type", "Node")
	var node_name = params.get("node_name", "NewNode")
	
	# Validation
	if not ClassDB.class_exists(node_type):
		return _send_error(client_id, "Invalid node type: %s" % node_type, command_id)
	
	# Get the parent node
	var parent = get_node_or_null(parent_path)
	if not parent:
		return _send_error(client_id, "Parent node not found: %s" % parent_path, command_id)
	
	# Create the new node
	var node
	
	if ClassDB.can_instantiate(node_type):
		node = ClassDB.instantiate(node_type)
	else:
		return _send_error(client_id, "Cannot instantiate node of type: %s" % node_type, command_id)
	
	if not node:
		return _send_error(client_id, "Failed to create node of type: %s" % node_type, command_id)
	
	# Set the node name
	node.name = node_name
	
	# Add the node to the parent
	parent.add_child(node)
	
	# Set owner for proper serialization
	if get_tree().edited_scene_root:
		node.owner = get_tree().edited_scene_root
	
	_send_success(client_id, {
		"node_path": node.get_path()
	}, command_id)

func _delete_node(client_id: int, params: Dictionary, command_id: String) -> void:
	var node_path = params.get("node_path", "")
	
	# Validation
	if node_path.is_empty():
		return _send_error(client_id, "Node path cannot be empty", command_id)
	
	# Get the node
	var node = get_node_or_null(node_path)
	if not node:
		return _send_error(client_id, "Node not found: %s" % node_path, command_id)
	
	# Cannot delete the root node
	if node == get_tree().root:
		return _send_error(client_id, "Cannot delete the root node", command_id)
	
	# Delete the node
	node.queue_free()
	
	_send_success(client_id, {
		"deleted_node_path": node_path
	}, command_id)

func _update_node_property(client_id: int, params: Dictionary, command_id: String) -> void:
	var node_path = params.get("node_path", "")
	var property_name = params.get("property", "")
	var property_value = params.get("value")
	
	# Validation
	if node_path.is_empty():
		return _send_error(client_id, "Node path cannot be empty", command_id)
	
	if property_name.is_empty():
		return _send_error(client_id, "Property name cannot be empty", command_id)
	
	if property_value == null:
		return _send_error(client_id, "Property value cannot be null", command_id)
	
	# Get the node
	var node = get_node_or_null(node_path)
	if not node:
		return _send_error(client_id, "Node not found: %s" % node_path, command_id)
	
	# Check if the property exists
	if not property_name in node:
		return _send_error(client_id, "Property %s does not exist on node %s" % [property_name, node_path], command_id)
	
	# Set the property
	node.set(property_name, property_value)
	
	_send_success(client_id, {
		"node_path": node_path,
		"property": property_name,
		"value": property_value
	}, command_id)

func _get_node_properties(client_id: int, params: Dictionary, command_id: String) -> void:
	var node_path = params.get("node_path", "")
	
	# Validation
	if node_path.is_empty():
		return _send_error(client_id, "Node path cannot be empty", command_id)
	
	# Get the node
	var node = get_node_or_null(node_path)
	if not node:
		return _send_error(client_id, "Node not found: %s" % node_path, command_id)
	
	# Get all properties
	var properties = {}
	var property_list = node.get_property_list()
	
	for prop in property_list:
		var name = prop["name"]
		if not name.begins_with("_"):  # Skip internal properties
			properties[name] = node.get(name)
	
	_send_success(client_id, {
		"node_path": node_path,
		"properties": properties
	}, command_id)

func _list_nodes(client_id: int, params: Dictionary, command_id: String) -> void:
	var parent_path = params.get("parent_path", "/root")
	
	# Get the parent node
	var parent = get_node_or_null(parent_path)
	if not parent:
		return _send_error(client_id, "Parent node not found: %s" % parent_path, command_id)
	
	# Get children
	var children = []
	for child in parent.get_children():
		children.append({
			"name": child.name,
			"type": child.get_class(),
			"path": child.get_path()
		})
	
	_send_success(client_id, {
		"parent_path": parent_path,
		"children": children
	}, command_id)

# Script operations
func _create_script(client_id: int, params: Dictionary, command_id: String) -> void:
	var script_path = params.get("script_path", "")
	var content = params.get("content", "")
	var node_path = params.get("node_path", "")
	
	# Validation
	if script_path.is_empty():
		return _send_error(client_id, "Script path cannot be empty", command_id)
	
	# Make sure we have an absolute path
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path
	
	if not script_path.ends_with(".gd"):
		script_path += ".gd"
	
	# Create the directory if it doesn't exist
	var dir = script_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		var err = DirAccess.make_dir_recursive_absolute(dir)
		if err != OK:
			return _send_error(client_id, "Failed to create directory: %s (Error code: %d)" % [dir, err], command_id)
	
	# Create the script file
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return _send_error(client_id, "Failed to create script file: %s" % script_path, command_id)
	
	file.store_string(content)
	file = null  # Close the file
	
	# Attach the script to a node if specified
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if not node:
			return _send_error(client_id, "Node not found: %s" % node_path, command_id)
		
		var script = load(script_path)
		if not script:
			return _send_error(client_id, "Failed to load script: %s" % script_path, command_id)
		
		node.set_script(script)
	
	_send_success(client_id, {
		"script_path": script_path,
		"node_path": node_path
	}, command_id)

func _edit_script(client_id: int, params: Dictionary, command_id: String) -> void:
	var script_path = params.get("script_path", "")
	var content = params.get("content", "")
	
	# Validation
	if script_path.is_empty():
		return _send_error(client_id, "Script path cannot be empty", command_id)
	
	if content.is_empty():
		return _send_error(client_id, "Content cannot be empty", command_id)
	
	# Make sure we have an absolute path
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path
	
	# Check if the file exists
	if not FileAccess.file_exists(script_path):
		return _send_error(client_id, "Script file not found: %s" % script_path, command_id)
	
	# Edit the script file
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return _send_error(client_id, "Failed to open script file: %s" % script_path, command_id)
	
	file.store_string(content)
	file = null  # Close the file
	
	_send_success(client_id, {
		"script_path": script_path
	}, command_id)

func _get_script(client_id: int, params: Dictionary, command_id: String) -> void:
	var script_path = params.get("script_path", "")
	var node_path = params.get("node_path", "")
	
	# Validation - either script_path or node_path must be provided
	if script_path.is_empty() and node_path.is_empty():
		return _send_error(client_id, "Either script_path or node_path must be provided", command_id)
	
	# If node_path is provided, get the script from the node
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if not node:
			return _send_error(client_id, "Node not found: %s" % node_path, command_id)
		
		var script = node.get_script()
		if not script:
			return _send_error(client_id, "Node does not have a script: %s" % node_path, command_id)
		
		script_path = script.resource_path
	
	# Make sure we have an absolute path
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path
	
	# Check if the file exists
	if not FileAccess.file_exists(script_path):
		return _send_error(client_id, "Script file not found: %s" % script_path, command_id)
	
	# Read the script file
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return _send_error(client_id, "Failed to open script file: %s" % script_path, command_id)
	
	var content = file.get_as_text()
	file = null  # Close the file
	
	_send_success(client_id, {
		"script_path": script_path,
		"content": content
	}, command_id)

# Scene operations
func _save_scene(client_id: int, params: Dictionary, command_id: String) -> void:
	var path = params.get("path", "")
	
	# If no path provided, use the current scene path
	if path.is_empty() and get_tree().edited_scene_root:
		path = get_tree().edited_scene_root.scene_file_path
	
	# Validation
	if path.is_empty():
		return _send_error(client_id, "Scene path cannot be empty", command_id)
	
	# Make sure we have an absolute path
	if not path.begins_with("res://"):
		path = "res://" + path
	
	if not path.ends_with(".tscn"):
		path += ".tscn"
	
	# Check if we have an edited scene
	if not get_tree().edited_scene_root:
		return _send_error(client_id, "No scene is currently being edited", command_id)
	
	# Save the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(get_tree().edited_scene_root)
	if result != OK:
		return _send_error(client_id, "Failed to pack scene: %d" % result, command_id)
	
	result = ResourceSaver.save(packed_scene, path)
	if result != OK:
		return _send_error(client_id, "Failed to save scene: %d" % result, command_id)
	
	_send_success(client_id, {
		"scene_path": path
	}, command_id)

func _open_scene(client_id: int, params: Dictionary, command_id: String) -> void:
	var path = params.get("path", "")
	
	# Validation
	if path.is_empty():
		return _send_error(client_id, "Scene path cannot be empty", command_id)
	
	# Make sure we have an absolute path
	if not path.begins_with("res://"):
		path = "res://" + path
	
	# Check if the file exists
	if not FileAccess.file_exists(path):
		return _send_error(client_id, "Scene file not found: %s" % path, command_id)
	
	# Since we can't directly open scenes in tool scripts,
	# we need to defer to the plugin which has access to EditorInterface
	var plugin = Engine.get_meta("GodotMCPPlugin") if Engine.has_meta("GodotMCPPlugin") else null
	
	if plugin and plugin.has_method("get_editor_interface"):
		var editor_interface = plugin.get_editor_interface()
		editor_interface.open_scene_from_path(path)
		_send_success(client_id, {
			"scene_path": path
		}, command_id)
	else:
		_send_error(client_id, "Cannot access EditorInterface. Please open the scene manually: %s" % path, command_id)

func _get_current_scene(client_id: int, _params: Dictionary, command_id: String) -> void:
	if not get_tree().edited_scene_root:
		return _send_error(client_id, "No scene is currently being edited", command_id)
	
	var scene_path = get_tree().edited_scene_root.scene_file_path
	if scene_path.is_empty():
		scene_path = "Untitled"
	
	_send_success(client_id, {
		"scene_path": scene_path,
		"root_node_type": get_tree().edited_scene_root.get_class(),
		"root_node_name": get_tree().edited_scene_root.name
	}, command_id)

# Resource operations
func _create_resource(client_id: int, params: Dictionary, command_id: String) -> void:
	var resource_type = params.get("resource_type", "")
	var resource_path = params.get("resource_path", "")
	var properties = params.get("properties", {})
	
	# Validation
	if resource_type.is_empty():
		return _send_error(client_id, "Resource type cannot be empty", command_id)
	
	if resource_path.is_empty():
		return _send_error(client_id, "Resource path cannot be empty", command_id)
	
	# Make sure we have an absolute path
	if not resource_path.begins_with("res://"):
		resource_path = "res://" + resource_path
	
	# Create the resource
	var resource
	
	if ClassDB.class_exists(resource_type):
		resource = ClassDB.instantiate(resource_type)
		if not resource:
			return _send_error(client_id, "Failed to instantiate resource: %s" % resource_type, command_id)
	else:
		return _send_error(client_id, "Invalid resource type: %s" % resource_type, command_id)
	
	# Set properties
	for key in properties:
		resource.set(key, properties[key])
	
	# Save the resource
	var result = ResourceSaver.save(resource, resource_path)
	if result != OK:
		return _send_error(client_id, "Failed to save resource: %d" % result, command_id)
	
	_send_success(client_id, {
		"resource_path": resource_path,
		"resource_type": resource_type
	}, command_id)

# Project operations
func _get_project_info(client_id: int, _params: Dictionary, command_id: String) -> void:
	var project_name = ProjectSettings.get_setting("application/config/name", "Untitled Project")
	var project_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	
	_send_success(client_id, {
		"project_name": project_name,
		"project_version": project_version,
		"godot_version": Engine.get_version_info(),
		"current_scene": get_tree().edited_scene_root.scene_file_path if get_tree().edited_scene_root else ""
	}, command_id)

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
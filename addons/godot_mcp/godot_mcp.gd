@tool
extends EditorPlugin

var websocket_server = null
var command_handler = null
var mcp_panel = null

func _enter_tree():
	# Initialize the websocket server
	websocket_server = preload("res://addons/godot_mcp/websocket_server.gd").new()
	add_child(websocket_server)
	
	# Initialize the command handler
	command_handler = preload("res://addons/godot_mcp/command_handler.gd").new()
	command_handler.name = "CommandHandler"
	websocket_server.add_child(command_handler)
	
	# Add the UI panel
	mcp_panel = preload("res://addons/godot_mcp/ui/mcp_panel.tscn").instantiate()
	mcp_panel.websocket_server = websocket_server
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, mcp_panel)
	
	print("Godot MCP plugin initialized")

func _exit_tree():
	# Stop the websocket server
	if websocket_server:
		if websocket_server.is_server_active():
			websocket_server.stop_server()
		remove_child(websocket_server)
		websocket_server.queue_free()
	
	# Remove the UI panel
	if mcp_panel:
		remove_control_from_docks(mcp_panel)
		mcp_panel.queue_free()
	
	print("Godot MCP plugin shut down")
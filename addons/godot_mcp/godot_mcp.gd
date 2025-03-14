@tool
extends EditorPlugin

var websocket_server = null
var command_handler = null
var mcp_panel = null

func _enter_tree():
	# Store plugin instance for EditorInterface access
	Engine.set_meta("GodotMCPPlugin", self)
	
	print("Godot MCP plugin initializing...")
	
	# Initialize the websocket server
	print("Creating WebSocket server...")
	websocket_server = preload("res://addons/godot_mcp/websocket_server.gd").new()
	add_child(websocket_server)
	
	# Initialize the command handler
	print("Creating command handler...")
	command_handler = preload("res://addons/godot_mcp/command_handler.gd").new()
	command_handler.name = "CommandHandler"
	websocket_server.add_child(command_handler)
	
	# Add the UI panel
	print("Creating MCP panel...")
	mcp_panel = preload("res://addons/godot_mcp/ui/mcp_panel.tscn").instantiate()
	mcp_panel.websocket_server = websocket_server
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, mcp_panel)
	
	# Start the WebSocket server automatically
	print("Starting WebSocket server on port", websocket_server.get_port(), "...")
	var result = websocket_server.start_server()
	if result == OK:
		print("WebSocket server started successfully on ws://localhost:" + str(websocket_server.get_port()))
	else:
		printerr("Failed to start WebSocket server: ", result)
	
	print("Godot MCP plugin initialized")

func _exit_tree():
	# Remove plugin instance from Engine metadata
	if Engine.has_meta("GodotMCPPlugin"):
		Engine.remove_meta("GodotMCPPlugin")
	
	# Stop the websocket server
	if websocket_server:
		if websocket_server.is_server_active():
			print("Stopping WebSocket server...")
			websocket_server.stop_server()
		remove_child(websocket_server)
		websocket_server.queue_free()
	
	# Remove the UI panel
	if mcp_panel:
		remove_control_from_docks(mcp_panel)
		mcp_panel.queue_free()
	
	print("Godot MCP plugin shut down")

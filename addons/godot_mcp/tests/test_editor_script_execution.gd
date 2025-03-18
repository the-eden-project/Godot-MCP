@tool
extends Node

# This script allows testing of the editor script execution functionality
# without going through the MCP server.

var _timer = null

func _ready():
	print("Starting editor script execution test...")
	
	# Create an instance of the script command processor
	var script_commands = MCPEditorScriptCommands.new()
	add_child(script_commands)
	
	# Sample script that would be received from a client
	var test_script = """
# Get the edited scene root
var root = EditorInterface.get_edited_scene_root()
print("Current scene root: ", root.name if root else "None")

# Find direct collision shape paths
var level_path = root.get_node("Level") if root else null
if level_path:
	# Fix specific collision shapes we know are problematic
	var paths = [
		"Level/MainPlatform/StaticBody/CollisionShape",
		"Level/Platform1/StaticBody/CollisionShape",
		"Level/Platform2/StaticBody/CollisionShape",
		"Level/Platform3/StaticBody/CollisionShape"
	]
	for path in paths:
		var shape_node = level_path.get_node(path)
		if shape_node and not shape_node.shape:
			print("Fixing collision shape at: ", path)
			var parent_csg = shape_node.get_parent().get_parent()
			var box_shape = BoxShape3D.new()
			box_shape.size = parent_csg.size
			shape_node.shape = box_shape
			print("Applied new box shape with size: ", box_shape.size)
	print("Completed targeted collision shape fixes")
else:
	print("Level node not found")
"""

	# Mock parameters for the command
	var params = {
		"code": test_script
	}
	
	# Create a callback to handle the results
	script_commands.connect("command_completed", _on_command_completed)
	
	# Execute the script with a mock client ID and command ID
	script_commands._execute_editor_script(1, params, "test_command")
	
	print("Test initiated - check the output for results...")
	
	# Create a timer to terminate the test if it doesn't complete in time
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 5.0  # Wait up to 5 seconds for the callback
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	_timer.start()

# Callback for when the command completes
func _on_command_completed(client_id: int, command_type: String, result_data: Dictionary, command_id: String) -> void:
	print("\n--- EDITOR SCRIPT EXECUTION RESULTS ---")
	print("Success: ", result_data.get("success", false))
	
	print("\nOutput:")
	var output = result_data.get("output", [])
	for line in output:
		print("  ", line)
	
	if result_data.has("error"):
		print("\nError: ", result_data.get("error"))
	
	if result_data.has("result"):
		print("\nResult: ", result_data.get("result"))
	
	print("--- END OF RESULTS ---\n")
	
	# Cleanup after test completes successfully
	_cleanup()

func _on_timeout():
	print("ERROR: Test timed out without receiving a command completion signal")
	_cleanup()

func _cleanup():
	if _timer:
		_timer.stop()
		_timer.queue_free()
		_timer = null
	
	# In a real test environment, you might want to:
	# get_tree().quit()

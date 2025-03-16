@tool
class_name MCPEditorScriptCommands
extends MCPBaseCommandProcessor

func process_command(client_id: int, command_type: String, params: Dictionary, command_id: String) -> bool:
	match command_type:
		"execute_editor_script":
			_execute_editor_script(client_id, params, command_id)
			return true
	return false  # Command not handled

func _execute_editor_script(client_id: int, params: Dictionary, command_id: String) -> void:
	var code = params.get("code", "")
	
	# Validation
	if code.is_empty():
		return _send_error(client_id, "Code cannot be empty", command_id)
	
	# Create a temporary script node to execute the code
	var script_node = Node.new()
	add_child(script_node)
	
	# Create a temporary script
	var script = GDScript.new()
	
	# Capture output with a custom print function
	var output = []
	
	# Create a custom print capture function
	var capture_print = func(text): output.append(str(text))
	
	var error_message = ""
	var execution_result = null
	
	# Prepare script with error handling
	var script_content = """
@tool
extends Node

# Variable to store the result
var result = null
func _ready():
	var scene = get_tree().edited_scene_root
	
	# Custom print function that captures output
	var print_capture = func(text): get_parent().capture_print(text)
	
	# Execute the provided code in a try-catch block
	try:
		# USER CODE START
{user_code}
		# USER CODE END
		
	except (error):
	except (error):
		printerr("Error executing script: " + str(error))
		get_parent()._on_script_error(str(error))
"""
	
	# Indent the user code
	var indented_code = ""
	var lines = code.split("\n")
	for line in lines:
		indented_code += "\t\t" + line + "\n"
	
	# Create methods to handle script errors and print capture
	script_node._on_script_error = func(error): 
		error_message = error
	
	# Add a capture_print method to our command processor instance that the script can call
	self.capture_print = capture_print
	
	# Assign the script to the node
	script_node.set_script(script)
		error_message = error
	
	# Assign the script to the node
	script_node.set_script(script)
	
	# Wait a frame to ensure the script has executed
	await get_tree().process_frame
	
	# Clean up our temporary capture_print method
	self.set_meta("capture_print", null)
		execution_result = script_node.result
	
	remove_child(script_node)
	script_node.queue_free()
	
	# Restore original print function
	print = original_print
	
	# Build the response
	var result_data = {
		"success": error_message.is_empty(),
		"output": output
	}
	
	if not error_message.is_empty():
		result_data["error"] = error_message
	elif execution_result != null:
		result_data["result"] = execution_result
	
	_send_success(client_id, result_data, command_id)
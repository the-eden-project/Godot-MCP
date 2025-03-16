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
	
	var output = []
	var error_message = ""
	var execution_result = null
	
	# Replace print() calls with custom_print() in the user code
	var modified_code = _replace_print_calls(code)
	
	# Prepare script with error handling and custom print function
	var script_content = """
@tool
extends Node

# Variable to store the result
var result = null
var _output_array = []

# Custom print function that stores output in the array
func custom_print(value):
	_output_array.append(str(value))
	print(value)  # Still print to the console for debugging

func _ready():
	var scene = get_tree().edited_scene_root
	
	# Execute the provided code in a try-catch block
	try:
		# USER CODE START
{user_code}
		# USER CODE END
		
	except (error):
		printerr("Error executing script: " + str(error))
		get_parent()._on_script_error(str(error))
"""
	
	# Indent the user code
	var indented_code = ""
	var lines = modified_code.split("\n")
	for line in lines:
		indented_code += "\t\t" + line + "\n"
	
	script_content = script_content.replace("{user_code}", indented_code)
	script.source_code = script_content
	script.reload()
	
	# Create a method to handle script errors
	script_node._on_script_error = func(error): 
		error_message = error
	
	# Create a method to retrieve the output
	script_node.get_output = func():
		return script_node._output_array if script_node.has_variable("_output_array") else []
	
	# Assign the script to the node
	script_node.set_script(script)
	
	# Wait a frame to ensure the script has executed
	await get_tree().process_frame
	
	# Collect results
	if script_node.has_method("result"):
		execution_result = script_node.result
	
	if script_node.has_method("get_output"):
		output = script_node.get_output()
	
	# Clean up
	remove_child(script_node)
	script_node.queue_free()
	
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

# Replace print() calls with custom_print() in the user code
func _replace_print_calls(code: String) -> String:
	var regex = RegEx.new()
	regex.compile("print\\s*\\((.+?)\\)")
	
	var result = regex.search_all(code)
	var modified_code = code
	
	# Process matches in reverse order to avoid issues with changing string length
	for i in range(result.size() - 1, -1, -1):
		var match_obj = result[i]
		var full_match = match_obj.get_string()
		var arg = match_obj.get_string(1)
		
		var replacement = "custom_print(" + arg + ")"
		
		var start = match_obj.get_start()
		var end = match_obj.get_end()
		
		modified_code = modified_code.substr(0, start) + replacement + modified_code.substr(end)
	
	return modified_code
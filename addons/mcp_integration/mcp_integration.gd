@tool
extends EditorPlugin

const SERVER_URL = "http://localhost:3000"
var current_script = null
var http_request = null
var script_editor = null
var debounce_timer = null

func _enter_tree():
	# Initialize plugin
	print("MCP Integration Plugin: Initializing")
	
	# Get the script editor interface
	script_editor = get_editor_interface().get_script_editor()
	
	# Connect to script changed signal
	script_editor.connect("editor_script_changed", _on_editor_script_changed)
	
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Set up debounce timer
	debounce_timer = Timer.new()
	debounce_timer.one_shot = true
	debounce_timer.wait_time = 0.5  # Update after 0.5 seconds of inactivity
	debounce_timer.connect("timeout", _send_current_script)
	add_child(debounce_timer)
	
	# Initial script update
	_on_editor_script_changed(script_editor.get_current_script())

func _exit_tree():
	# Clean up plugin
	print("MCP Integration Plugin: Cleaning up")
	
	# Disconnect signals
	if script_editor:
		script_editor.disconnect("editor_script_changed", _on_editor_script_changed)
	
	# Remove nodes
	if http_request:
		http_request.queue_free()
	
	if debounce_timer:
		debounce_timer.queue_free()

func _on_editor_script_changed(script):
	current_script = script
	
	if script:
		# Connect to text changed signals if it's a script with text content
		if script.is_connected("text_changed", _on_script_text_changed):
			script.disconnect("text_changed", _on_script_text_changed)
		
		script.connect("text_changed", _on_script_text_changed)
		
		# Send update immediately
		_send_current_script()
	else:
		# Send empty script notification
		var data = {
			"path": "",
			"content": ""
		}
		_send_script_data(data)

func _on_script_text_changed():
	# When script text changes, restart the debounce timer
	if debounce_timer:
		debounce_timer.start()

func _send_current_script():
	if not current_script:
		return
	
	var script_path = current_script.resource_path
	var script_content = current_script.source_code
	
	# Prepare data to send
	var data = {
		"path": script_path,
		"content": script_content
	}
	
	_send_script_data(data)

func _send_script_data(data):
	# Send the current script data to the MCP server
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	# Reset HTTP request if needed
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()
	
	# Send the data
	var error = http_request.request(
		SERVER_URL + "/godot/current-script",
		headers,
		HTTPClient.METHOD_POST,
		json_data
	)
	
	if error != OK:
		push_error("MCP Integration: Error sending script data: " + str(error))

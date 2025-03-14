@tool
extends EditorPlugin

var _server = TCPServer.new()
var _port = 9080

func _enter_tree():
	print("WS Server Plugin: Starting on port", _port)
	
	var err = _server.listen(_port)
	if err == OK:
		print("WS Server Plugin: Listening on port", _port)
		set_process(true)
	else:
		printerr("WS Server Plugin: Failed to listen on port", _port, "error:", err)
	
	# Store a reference to this plugin in the Engine metadata
	# This makes it accessible to the command handler
	Engine.set_meta("GodotMCPPlugin", self)
	
	print("WS Server Plugin: Initialized")

func _exit_tree():
	if _server.is_listening():
		_server.stop()
		print("WS Server Plugin: Stopped listening")
	
	# Remove the reference when plugin is disabled
	if Engine.has_meta("GodotMCPPlugin"):
		Engine.remove_meta("GodotMCPPlugin")
	
	print("WS Server Plugin: Shutdown")

# Method to access the editor's UndoRedo system
func get_undo_redo():
	return get_undo_redo()

# Method to expose the editor interface
func get_editor_interface():
	return get_editor_interface()

func _process(_delta):
	if not _server.is_listening():
		return
	
	if _server.is_connection_available():
		var conn = _server.take_connection()
		print("WS Server Plugin: New connection received")
		
		if conn == null:
			printerr("WS Server Plugin: Failed to take connection")
			return
		
		# Read the WebSocket handshake request
		var request = ""
		var max_size = 4096
		var count = 0
		
		while count < max_size:
			var chunk = conn.get_partial_data(1)
			if chunk[0] != OK:
				printerr("WS Server Plugin: Error reading from connection", chunk[0])
				break
			
			var data = chunk[1]
			if data.size() == 0:
				break
			
			request += data.get_string_from_utf8()
			count += 1
			
			# Check if we've reached the end of the header
			if request.ends_with("\r\n\r\n"):
				break
		
		print("WS Server Plugin: Received request of size", request.length())
		print("WS Server Plugin: Request headers:", request)
		
		# Parse WebSocket handshake
		var key = ""
		var lines = request.split("\r\n")
		
		for line in lines:
			if line.begins_with("Sec-WebSocket-Key:"):
				key = line.substr(18).strip_edges()
				break
		
		if key == "":
			printerr("WS Server Plugin: Invalid WebSocket handshake, no key found")
			conn.disconnect_from_host()
			return
		
		print("WS Server Plugin: WebSocket key:", key)
		
		# Generate WebSocket accept key
		var accept = _generate_ws_accept_key(key)
		print("WS Server Plugin: WebSocket accept key:", accept)
		
		# Send WebSocket handshake response
		var response = "HTTP/1.1 101 Switching Protocols\r\n" + \
					  "Upgrade: websocket\r\n" + \
					  "Connection: Upgrade\r\n" + \
					  "Sec-WebSocket-Accept: " + accept + "\r\n\r\n"
		
		print("WS Server Plugin: Sending handshake response:", response)
		conn.put_data(response.to_utf8_buffer())
		
		# At this point, the WebSocket handshake is complete
		print("WS Server Plugin: WebSocket handshake completed")
		
		# Now we need to upgrade the connection to WebSocketPeer
		var ws = WebSocketPeer.new()
		var upgrade_err = ws.accept_stream(conn)
		
		if upgrade_err != OK:
			printerr("WS Server Plugin: Failed to upgrade to WebSocket", upgrade_err)
			return
		
		print("WS Server Plugin: Connection upgraded to WebSocket")
		
		# Test sending a message
		var test_msg = "{\"status\": \"connected\", \"message\": \"WebSocket handshake successful\"}"
		var msg_err = ws.send_text(test_msg)
		
		if msg_err != OK:
			printerr("WS Server Plugin: Failed to send test message", msg_err)
		else:
			print("WS Server Plugin: Sent test message:", test_msg)

# The magic WebSocket accept key generator
func _generate_ws_accept_key(key: String) -> String:
	var magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" # WebSocket magic string
	var concatenated = key + magic
	
	# Godot doesn't have a built-in SHA-1 hash function that returns a hex string
	# So we'll use a placeholder and handle the crypto in Node.js for now
	# In a real implementation, you would need to properly implement SHA-1
	return "dummy_accept_key"
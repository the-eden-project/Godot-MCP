@tool
extends EditorPlugin

var _server = TCPServer.new()
var _port = 9080
var _websocket_peers = {}

func _enter_tree():
	print("WS Server Plugin: Starting on port", _port)
	
	var err = _server.listen(_port)
	if err == OK:
		print("WS Server Plugin: Listening on port", _port)
		set_process(true)
	else:
		printerr("WS Server Plugin: Failed to listen on port", _port, "error:", err)
	
	print("WS Server Plugin: Initialized")

func _exit_tree():
	if _server.is_listening():
		_server.stop()
		print("WS Server Plugin: Stopped listening")
	
	# Close all WebSocket connections
	for peer_id in _websocket_peers:
		var peer = _websocket_peers[peer_id]
		peer.close()
	
	_websocket_peers.clear()
	print("WS Server Plugin: Shutdown")

func _process(_delta):
	if not _server.is_listening():
		return
	
	# Check for new connections
	if _server.is_connection_available():
		var conn = _server.take_connection()
		print("WS Server Plugin: New connection received")
		
		if conn == null:
			printerr("WS Server Plugin: Failed to take connection")
			return
		
		# Create WebSocketPeer and accept the connection directly
		var ws = WebSocketPeer.new()
		print("WS Server Plugin: Created WebSocketPeer")
		
		var err = ws.accept_stream(conn)
		if err != OK:
			printerr("WS Server Plugin: Failed to accept stream:", err)
			return
		
		print("WS Server Plugin: Accepted stream, WebSocket handshake starting")
		
		# Generate a client ID and store the WebSocket peer
		var client_id = randi() % 100000000
		_websocket_peers[client_id] = ws
		
		print("WS Server Plugin: Added client", client_id)
	
	# Process existing WebSocket connections
	var clients_to_remove = []
	
	for client_id in _websocket_peers:
		var ws = _websocket_peers[client_id]
		ws.poll()
		
		var state = ws.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			# Handle incoming messages
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var text = packet.get_string_from_utf8()
				print("WS Server Plugin: Received from client", client_id, ":", text)
				
				# Parse the JSON command
				var json = JSON.new()
				var parse_result = json.parse(text)
				
				if parse_result == OK:
					var command = json.get_data()
					print("WS Server Plugin: Parsed command:", command)
					
					# Send a response
					var response = {
						"status": "success",
						"message": "Command received",
						"commandId": command.get("commandId", "unknown")
					}
					
					var response_text = JSON.stringify(response)
					print("WS Server Plugin: Sending response:", response_text)
					
					ws.send_text(response_text)
				else:
					print("WS Server Plugin: Failed to parse JSON:", json.get_error_message())
		
		elif state == WebSocketPeer.STATE_CLOSING or state == WebSocketPeer.STATE_CLOSED:
			print("WS Server Plugin: Client", client_id, "disconnected (state:", state, ")")
			clients_to_remove.append(client_id)
		
		elif state == WebSocketPeer.STATE_CONNECTING:
			print("WS Server Plugin: Client", client_id, "still connecting...")
	
	# Remove disconnected clients
	for client_id in clients_to_remove:
		_websocket_peers.erase(client_id)
@tool
extends EditorPlugin

var _tcp_server := TCPServer.new()
var _port := 9080
var _websocket_peers := {}

func _enter_tree():
	print("Simple WS Server: Starting on port", _port)
	
	var err = _tcp_server.listen(_port)
	if err == OK:
		print("Simple WS Server: Listening on port", _port)
		set_process(true)
	else:
		printerr("Simple WS Server: Failed to listen on port", _port, "error:", err)
	
	print("Simple WS Server: Plugin initialized")

func _exit_tree():
	if _tcp_server.is_listening():
		_tcp_server.stop()
		print("Simple WS Server: Stopped listening")
	
	# Close all WebSocket connections
	for peer_id in _websocket_peers:
		_websocket_peers[peer_id].close()
	_websocket_peers.clear()
	
	print("Simple WS Server: Plugin shutdown")

func _process(_delta):
	if not _tcp_server.is_listening():
		return
	
	# Accept new connections
	while _tcp_server.is_connection_available():
		print("Simple WS Server: New connection available")
		var tcp_connection = _tcp_server.take_connection()
		
		if tcp_connection != null:
			print("Simple WS Server: TCP connection accepted")
			var ws_peer = WebSocketPeer.new()
			
			# Configure WebSocketPeer
			# Set handshake timeout (in milliseconds)
			print("Simple WS Server: Created WebSocketPeer, accepting stream...")
			var err = ws_peer.accept_stream(tcp_connection)
			
			if err != OK:
				printerr("Simple WS Server: Failed to accept WebSocket stream:", err)
				continue
				
			print("Simple WS Server: WebSocket handshake started")
			
			# Register the new WebSocket peer
			var peer_id = randi() % 1000000 + 1
			_websocket_peers[peer_id] = ws_peer
	
	# Poll all connected WebSocket peers
	var peers_to_remove = []
	
	for peer_id in _websocket_peers:
		var ws_peer = _websocket_peers[peer_id]
		ws_peer.poll()
		
		# Handle WebSocket state
		var state = ws_peer.get_ready_state()
		match state:
			WebSocketPeer.STATE_CONNECTING:
				print("Simple WS Server: Peer", peer_id, "connecting...")
				
			WebSocketPeer.STATE_OPEN:
				# Handle open connection
				if !ws_peer.has_meta("connection_logged"):
					print("Simple WS Server: Peer", peer_id, "connection established")
					ws_peer.set_meta("connection_logged", true)
				
				# Process incoming messages
				while ws_peer.get_available_packet_count() > 0:
					var packet = ws_peer.get_packet()
					var text = packet.get_string_from_utf8()
					print("Simple WS Server: Received from", peer_id, ":", text)
					
					# Parse JSON
					var json = JSON.new()
					var parse_result = json.parse(text)
					
					if parse_result == OK:
						var data = json.get_data()
						print("Simple WS Server: Parsed JSON:", data)
						
						# Send a response
						var response = {
							"status": "success",
							"message": "Command received successfully",
							"commandId": data.get("commandId", "unknown")
						}
						
						var response_text = JSON.stringify(response)
						ws_peer.send_text(response_text)
						print("Simple WS Server: Sent response to", peer_id)
					else:
						print("Simple WS Server: Failed to parse JSON:", json.get_error_message())
						
			WebSocketPeer.STATE_CLOSING:
				print("Simple WS Server: Peer", peer_id, "closing")
				
			WebSocketPeer.STATE_CLOSED:
				print("Simple WS Server: Peer", peer_id, "disconnected")
				peers_to_remove.append(peer_id)
	
	# Remove closed connections
	for peer_id in peers_to_remove:
		_websocket_peers.erase(peer_id)
@tool
extends EditorPlugin

var tcp_server := TCPServer.new()
var port := 9080
var handshake_timeout := 3000 # ms
var debug_mode := true

class WebSocketClient:
	var tcp: StreamPeerTCP
	var id: int
	var ws: WebSocketPeer
	var state: int = -1 # -1: handshaking, 0: connected, 1: error/closed
	var handshake_time: int
	var last_poll_time: int
	
	func _init(p_tcp: StreamPeerTCP, p_id: int):
		tcp = p_tcp
		id = p_id
		handshake_time = Time.get_ticks_msec()
	
	func upgrade_to_websocket() -> bool:
		ws = WebSocketPeer.new()
		var err = ws.accept_stream(tcp)
		return err == OK

var clients := {}
var next_client_id := 1

func _enter_tree():
	print("\n=== FINAL ATTEMPT SERVER STARTING ===")
	var err = tcp_server.listen(port)
	
	if err == OK:
		print("Listening on port", port)
		set_process(true)
	else:
		printerr("Failed to listen on port", port, "error:", err)
	
	print("=== SERVER INITIALIZED ===\n")

func _exit_tree():
	if tcp_server and tcp_server.is_listening():
		tcp_server.stop()
	
	clients.clear()
	
	print("=== SERVER SHUTDOWN ===")

func _process(_delta):
	if not tcp_server.is_listening():
		return
	
	# Poll for new connections
	if tcp_server.is_connection_available():
		var tcp = tcp_server.take_connection()
		var id = next_client_id
		next_client_id += 1
		
		var client = WebSocketClient.new(tcp, id)
		clients[id] = client
		
		print("[Client ", id, "] New TCP connection")
		
		# Try to upgrade immediately
		if client.upgrade_to_websocket():
			print("[Client ", id, "] WebSocket handshake started")
		else:
			print("[Client ", id, "] Failed to start WebSocket handshake")
			clients.erase(id)
	
	# Update clients
	var current_time = Time.get_ticks_msec()
	var ids_to_remove := []
	
	for id in clients:
		var client = clients[id]
		client.last_poll_time = current_time
		
		# Process client based on its state
		if client.state == -1: # Handshaking
			if client.ws != null:
				# Poll the WebSocket peer
				client.ws.poll()
				
				# Check WebSocket state
				var ws_state = client.ws.get_ready_state()
				if debug_mode:
					print("[Client ", id, "] State: ", ws_state)
					
				if ws_state == WebSocketPeer.STATE_OPEN:
					print("[Client ", id, "] WebSocket handshake completed")
					client.state = 0
					
					# Send welcome message
					var msg = JSON.stringify({
						"type": "welcome",
						"message": "Welcome to Godot WebSocket Server"
					})
					client.ws.send_text(msg)
					
				elif ws_state != WebSocketPeer.STATE_CONNECTING:
					print("[Client ", id, "] WebSocket handshake failed, state: ", ws_state)
					ids_to_remove.append(id)
				
				# Check for handshake timeout
				elif current_time - client.handshake_time > handshake_timeout:
					print("[Client ", id, "] WebSocket handshake timed out")
					ids_to_remove.append(id)
			else:
				# If TCP is still connected, try upgrading
				if client.tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
					if client.upgrade_to_websocket():
						print("[Client ", id, "] WebSocket handshake started")
					else:
						print("[Client ", id, "] Failed to start WebSocket handshake")
						ids_to_remove.append(id)
				else:
					print("[Client ", id, "] TCP disconnected during handshake")
					ids_to_remove.append(id)
		
		elif client.state == 0: # Connected
			# Poll the WebSocket
			client.ws.poll()
			
			# Check state
			var ws_state = client.ws.get_ready_state()
			if ws_state != WebSocketPeer.STATE_OPEN:
				print("[Client ", id, "] WebSocket connection closed, state: ", ws_state)
				ids_to_remove.append(id)
				continue
			
			# Process messages
			while client.ws.get_available_packet_count() > 0:
				var packet = client.ws.get_packet()
				var text = packet.get_string_from_utf8()
				
				print("[Client ", id, "] Received: ", text)
				
				# Parse as JSON
				var json = JSON.new()
				if json.parse(text) == OK:
					var data = json.get_data()
					
					# Handle JSON-RPC protocol
					if data.has("jsonrpc") and data.get("jsonrpc") == "2.0":
						# Handle ping method
						if data.has("method") and data.get("method") == "ping":
							var response = {
								"jsonrpc": "2.0",
								"id": data.get("id"),
								"result": null  # FastMCP expects null result for pings
							}
							var response_text = JSON.stringify(response)
							client.ws.send_text(response_text)
							print("[Client ", id, "] Sent ping response: ", response_text)
						
						# Handle other MCP commands
						elif data.has("method"):
							var method_name = data.get("method")
							var params = data.get("params", {})
							var req_id = data.get("id")
							
							print("[Client ", id, "] Processing method: ", method_name)
							
							# Generic success response
							var response = {
								"jsonrpc": "2.0",
								"id": req_id,
								"result": {
									"status": "success",
									"message": "Command processed"
								}
							}
							
							var response_text = JSON.stringify(response)
							client.ws.send_text(response_text)
							print("[Client ", id, "] Sent response: ", response_text)
					
					# Handle legacy command format
					elif data.has("type"):
						var cmd_type = data.get("type")
						var params = data.get("params", {})
						var cmd_id = data.get("commandId", "")
						
						print("[Client ", id, "] Processing legacy command: ", cmd_type)
						
						# Send response
						var response = {
							"status": "success",
							"message": "Command processed",
							"commandId": cmd_id
						}
						
						var response_text = JSON.stringify(response)
						client.ws.send_text(response_text)
						print("[Client ", id, "] Sent response: ", response_text)
	
	# Remove clients that need to be removed
	for id in ids_to_remove:
		clients.erase(id)

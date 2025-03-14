@tool
extends EditorPlugin

var _server = TCPServer.new()
var _clients = {}
var _port = 9080

func _enter_tree():
	print("\n=== ULTRA SIMPLE WEBSOCKET SERVER STARTING ===")
	
	# Start the TCP server
	var err = _server.listen(_port)
	if err == OK:
		print("Server listening on port %d" % _port)
		set_process(true)
	else:
		printerr("Failed to start server: %d" % err)
	
	print("=== SERVER INITIALIZED ===\n")

func _exit_tree():
	if _server.is_listening():
		_server.stop()
	
	for client_id in _clients.keys():
		_clients[client_id].close()
	
	_clients.clear()
	set_process(false)
	print("=== SERVER STOPPED ===")

func _process(_delta):
	# Accept new connections
	if _server.is_connection_available():
		var connection = _server.take_connection()
		print("\n=== NEW CONNECTION AVAILABLE ===")
		
		var websocket_peer = WebSocketPeer.new()
		print("WebSocket peer created")
		
		var err = websocket_peer.accept_stream(connection)
		print("accept_stream result: %d" % err)
		
		# Create a unique ID for this client
		var client_id = randi() % 1000000
		_clients[client_id] = websocket_peer
		
		print("Client %d registered" % client_id)
	
	# Process existing clients
	var clients_to_remove = []
	
	for client_id in _clients:
		var peer = _clients[client_id]
		peer.poll()
		
		var state = peer.get_ready_state()
		print("Client %d state: %d" % [client_id, state])
		
		if state == WebSocketPeer.STATE_CLOSED:
			clients_to_remove.append(client_id)
			print("Client %d disconnected" % client_id)
			continue
		elif state == WebSocketPeer.STATE_OPEN:
			print("Client %d connection open" % client_id)
			
			# Check for messages
			while peer.get_available_packet_count() > 0:
				var packet = peer.get_packet()
				var message = packet.get_string_from_utf8()
				print("Received from client %d: %s" % [client_id, message])
				
				# Send a response
				var response = "{\"status\": \"success\", \"message\": \"Echo: %s\"}" % message
				peer.send_text(response)
				print("Sent to client %d: %s" % [client_id, response])
	
	# Remove disconnected clients
	for id in clients_to_remove:
		_clients.erase(id)
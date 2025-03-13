@tool
class_name MCPWebSocketServer
extends Node

signal client_connected(id)
signal client_disconnected(id)
signal command_received(client_id, command)

var _server = TCPServer.new()
var _websocket_peer = WebSocketPeer.new()
var _clients = {}
var _port = 9080

func _ready():
	set_process(false)

func is_server_active() -> bool:
	return _server.is_listening()

func start_server() -> int:
	if is_server_active():
		return ERR_ALREADY_IN_USE
	
	var err = _server.listen(_port)
	if err == OK:
		set_process(true)
		print("MCP WebSocket server started on port %d" % _port)
	else:
		print("Failed to start MCP WebSocket server: %d" % err)
	
	return err

func stop_server() -> void:
	if is_server_active():
		_server.stop()
		
		# Close all client connections
		for client_id in _clients.keys():
			_clients[client_id].close()
		_clients.clear()
		
		set_process(false)
		print("MCP WebSocket server stopped")

func _process(_delta):
	if not is_server_active():
		return
	
	# Check for new connections
	if _server.is_connection_available():
		var connection = _server.take_connection()
		var peer = WebSocketPeer.new()
		peer.accept_stream(connection)
		
		# Generate a client ID
		var client_id = get_instance_id() + _clients.size() + 1
		_clients[client_id] = peer
		
		print("Client connected with ID: %d" % client_id)
		emit_signal("client_connected", client_id)
	
	# Process existing clients
	var clients_to_remove = []
	for client_id in _clients:
		var peer = _clients[client_id]
		
		# Poll the connection
		peer.poll()
		
		# Handle state changes
		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			clients_to_remove.append(client_id)
			continue
		
		# Handle incoming messages
		while peer.get_available_packet_count() > 0:
			var packet = peer.get_packet()
			var text = packet.get_string_from_utf8()
			
			# Parse the JSON command
			var json = JSON.new()
			var parse_result = json.parse(text)
			
			if parse_result == OK:
				var command = json.get_data()
				print("Received command from client %d: %s" % [client_id, command])
				emit_signal("command_received", client_id, command)
			else:
				print("Error parsing JSON from client %d: %s at line %d" % 
					[client_id, json.get_error_message(), json.get_error_line()])
	
	# Remove disconnected clients
	for client_id in clients_to_remove:
		print("Client disconnected: %d" % client_id)
		_clients.erase(client_id)
		emit_signal("client_disconnected", client_id)

func send_response(client_id: int, response: Dictionary) -> int:
	if not _clients.has(client_id):
		print("Error: Client %d not found" % client_id)
		return ERR_DOES_NOT_EXIST
	
	var peer = _clients[client_id]
	var json_text = JSON.stringify(response)
	
	if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("Error: Client %d connection not open" % client_id)
		return ERR_UNAVAILABLE
	
	var result = peer.send_text(json_text)
	if result != OK:
		print("Error sending response to client %d: %d" % [client_id, result])
	
	return result

func set_port(new_port: int) -> void:
	if is_server_active():
		push_error("Cannot change port while server is active")
		return
	_port = new_port

func get_port() -> int:
	return _port

func get_client_count() -> int:
	return _clients.size()
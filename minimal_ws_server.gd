@tool
extends EditorPlugin

var tcp_server = TCPServer.new()
var peers = {}
var pending_peers = []
var port = 9080
var handshake_timeout = 3000

class PendingPeer:
	var tcp: StreamPeerTCP
	var ws: WebSocketPeer = null
	var connect_time: int
	
	func _init(p_tcp: StreamPeerTCP):
		tcp = p_tcp
		connect_time = Time.get_ticks_msec()

func _enter_tree():
	print("\nMinimal WebSocket Server Plugin initializing...")
	
	# Start the TCP server
	var err = tcp_server.listen(port)
	if err == OK:
		print("TCP server listening on port " + str(port))
		set_process(true)
	else:
		printerr("Failed to start TCP server: " + str(err))
	
	print("Minimal WebSocket Server Plugin initialized\n")

func _exit_tree():
	if tcp_server.is_listening():
		tcp_server.stop()
		print("TCP server stopped")
	
	for client_id in peers:
		peers[client_id].close()
	
	peers.clear()
	pending_peers.clear()
	set_process(false)
	print("Minimal WebSocket Server Plugin shutdown")

func _process(_delta):
	if not tcp_server.is_listening():
		return
	
	# Accept new connections
	while tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		if conn == null:
			printerr("Failed to take TCP connection")
			continue
		
		print("New TCP connection accepted, starting WebSocket handshake...")
		pending_peers.append(PendingPeer.new(conn))
	
	# Process pending connections
	var to_remove := []
	for p in pending_peers:
		if not _connect_pending(p):
			if p.connect_time + handshake_timeout < Time.get_ticks_msec():
				print("WebSocket handshake timed out")
				to_remove.append(p)
			continue
		to_remove.append(p)
	
	for r in to_remove:
		pending_peers.erase(r)
	
	# Process connected clients
	to_remove.clear()
	for id in peers:
		var peer = peers[id]
		peer.poll()
		
		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			print("Client " + str(id) + " disconnected")
			to_remove.append(id)
			continue
		
		# Process messages
		while peer.get_available_packet_count() > 0:
			var packet = peer.get_packet()
			var text = packet.get_string_from_utf8()
			print("Received message from client " + str(id) + ": " + text)
			
			# Echo back with a prefix
			var response = "Echo: " + text
			peer.send_text(response)
			print("Sent response to client " + str(id) + ": " + response)
	
	for r in to_remove:
		peers.erase(r)

func _connect_pending(p: PendingPeer) -> bool:
	if p.ws != null:
		p.ws.poll()
		var state = p.ws.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			var id = randi() % (1 << 30) + 1
			peers[id] = p.ws
			print("WebSocket connection established for client " + str(id))
			return true
		elif state != WebSocketPeer.STATE_CONNECTING:
			print("WebSocket handshake failed, state: " + str(state))
			return true
		return false
	elif p.tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("TCP connection lost during handshake")
		return true
	else:
		print("TCP connected, upgrading to WebSocket...")
		p.ws = WebSocketPeer.new()
		var err = p.ws.accept_stream(p.tcp)
		if err != OK:
			printerr("Failed to accept WebSocket stream: " + str(err))
			return true
		print("WebSocket handshake started...")
		return false

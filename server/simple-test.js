// Simple WebSocket test client that will send a ping message
const WebSocket = require('ws');

console.log('Starting simple WebSocket test client...');

const ws = new WebSocket('ws://localhost:9080', {
  perMessageDeflate: false,
  handshakeTimeout: 5000
});

ws.on('open', function() {
  console.log('Connected to WebSocket server!');
  
  // Send a JSON-RPC ping message
  const pingMessage = {
    method: "ping",
    jsonrpc: "2.0",
    id: 12345
  };
  
  console.log('Sending ping message:', JSON.stringify(pingMessage));
  ws.send(JSON.stringify(pingMessage));
  
  // Also send a simple text message
  setTimeout(() => {
    console.log('Sending plain text message: "HELLO GODOT"');
    ws.send('HELLO GODOT');
  }, 1000);
});

ws.on('message', function(data) {
  console.log('Received response:', data.toString());
});

ws.on('error', function(error) {
  console.error('WebSocket error:', error.message);
  process.exit(1);
});

ws.on('close', function() {
  console.log('Connection closed');
  process.exit(0);
});

// Exit after 10 seconds
setTimeout(() => {
  console.log('Test timeout reached, closing...');
  ws.close();
  process.exit(0);
}, 10000);

console.log('Connecting to WebSocket server...');
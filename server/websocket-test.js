const WebSocket = require('ws');

console.log('Starting WebSocket test client...');

// Create a WebSocket client
const ws = new WebSocket('ws://localhost:9080', {
  // Try without any specific options first
  timeout: 5000,
  handshakeTimeout: 5000
});

// Connection opened
ws.on('open', function() {
  console.log('Connection established!');
  
  // Send a simple test message
  const testMessage = {
    type: 'get_project_info',
    params: {},
    commandId: 'test_cmd_1'
  };
  
  console.log('Sending test message:', JSON.stringify(testMessage));
  ws.send(JSON.stringify(testMessage));
});

// Error handling
ws.on('error', function(error) {
  console.error('WebSocket error:', error.message);
});

// Connection closed
ws.on('close', function(code, reason) {
  console.log(`Connection closed. Code: ${code}, Reason: ${reason || 'No reason provided'}`);
});

// Message received
ws.on('message', function(data) {
  console.log('Received message:', data.toString());
  
  // Close the connection after receiving a response
  console.log('Test complete, closing connection.');
  ws.close();
});

// Set a timeout to close the connection if nothing happens
setTimeout(() => {
  if (ws.readyState !== WebSocket.CLOSED && ws.readyState !== WebSocket.CLOSING) {
    console.log('Test timed out after 10 seconds. Closing connection.');
    ws.close();
  }
}, 10000);

console.log('WebSocket client initialized, waiting for connection...');
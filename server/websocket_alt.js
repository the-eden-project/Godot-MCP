// Alternative WebSocket client implementation
const WebSocketClient = require('websocket').client;
 
const client = new WebSocketClient();

console.log('=== STARTING ALTERNATIVE WEBSOCKET CLIENT ===');
 
client.on('connectFailed', function(error) {
    console.log('Connect Error: ' + error.toString());
});
 
client.on('connect', function(connection) {
    console.log('WebSocket Client Connected');
    
    connection.on('error', function(error) {
        console.log("Connection Error: " + error.toString());
    });
    
    connection.on('close', function() {
        console.log('Connection Closed');
    });
    
    connection.on('message', function(message) {
        if (message.type === 'utf8') {
            console.log("Received: '" + message.utf8Data + "'");
        }
        
        // Close after receiving a message
        connection.close();
    });
    
    if (connection.connected) {
        // Send a test message
        const msg = JSON.stringify({ 
          type: 'test',
          params: { message: 'Hello, Godot!' },
          commandId: 'alt-test-1'
        });
        
        console.log('Sending message: ' + msg);
        connection.sendUTF(msg);
    }
});

// Connect to the Godot WebSocket server
console.log('Connecting to ws://localhost:9080...');
client.connect('ws://localhost:9080');

// Exit after 10 seconds if nothing happens
setTimeout(function() {
    console.log('Timeout reached, exiting...');
    process.exit(1);
}, 10000);
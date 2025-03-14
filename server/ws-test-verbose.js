const WebSocket = require('ws');
const http = require('http');
const net = require('net');

console.log('Starting WebSocket test client with verbose logging...');

// First check if the TCP port is open
console.log('Checking if port 9080 is open...');
const socket = new net.Socket();

socket.setTimeout(3000);
socket.on('connect', function() {
    console.log('TCP port 9080 is open!');
    socket.destroy();
    startWebSocketTest();
});

socket.on('timeout', function() {
    console.log('TCP connection timeout. The port might be closed or blocked.');
    socket.destroy();
});

socket.on('error', function(err) {
    console.log('TCP connection error: Port 9080 is not reachable.', err.message);
});

socket.connect(9080, 'localhost');

function startWebSocketTest() {
    console.log('Initializing WebSocket connection...');

    const ws = new WebSocket('ws://localhost:9080', {
        perMessageDeflate: false,
        maxPayload: 100 * 1024 * 1024,
        handshakeTimeout: 8000
    });

    // Connection opening
    ws.on('open', function() {
        console.log('Connection established!');
        console.log('WebSocket state:', ws.readyState);
        
        // Send a simple test message
        const testMessage = {
            type: 'get_project_info',
            params: {},
            commandId: 'test_cmd_1'
        };
        
        console.log('Sending test message:', JSON.stringify(testMessage));
        ws.send(JSON.stringify(testMessage));
    });

    // Show connection upgrade info
    ws.on('upgrade', function(response) {
        console.log('Connection upgrade response:');
        console.log('  Status:', response.statusCode);
        console.log('  Headers:', response.headers);
    });

    // Error handling
    ws.on('error', function(error) {
        console.error('WebSocket error:', error);
        console.log('WebSocket state:', ws.readyState);
    });

    // Connection closed
    ws.on('close', function(code, reason) {
        console.log(`Connection closed. Code: ${code}, Reason: ${reason || 'No reason provided'}`);
        console.log('WebSocket state:', ws.readyState);
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
            console.log('WebSocket state:', ws.readyState);
            ws.close();
        }
    }, 10000);

    console.log('WebSocket client initialized, waiting for connection...');
}
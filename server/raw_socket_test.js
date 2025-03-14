// This is a raw socket test to check the handshake manually
const net = require('net');
const crypto = require('crypto');

// Generate a WebSocket key
const key = crypto.randomBytes(16).toString('base64');
console.log('Generated key:', key);

// Create a TCP socket
const client = new net.Socket();

console.log('=== RAW SOCKET TEST FOR WEBSOCKET HANDSHAKE ===');

client.connect(9080, 'localhost', function() {
    console.log('Connected to TCP server');
    
    // Send WebSocket handshake
    const handshake = 
        'GET / HTTP/1.1\r\n' +
        'Host: localhost:9080\r\n' +
        'Upgrade: websocket\r\n' +
        'Connection: Upgrade\r\n' +
        'Sec-WebSocket-Key: ' + key + '\r\n' +
        'Sec-WebSocket-Version: 13\r\n' +
        '\r\n';
    
    console.log('Sending handshake:\n' + handshake);
    client.write(handshake);
});

client.on('data', function(data) {
    console.log('Received:\n' + data.toString());
    
    // Check if it's a valid WebSocket handshake response
    const response = data.toString();
    if (response.includes('HTTP/1.1 101') && 
        response.toLowerCase().includes('upgrade: websocket') &&
        response.toLowerCase().includes('connection: upgrade')) {
        
        console.log('Valid WebSocket handshake response received!');
        
        // We're not implementing full WebSocket framing here, just checking handshake
        console.log('Handshake successful, closing connection...');
    } else {
        console.log('Invalid or incomplete WebSocket handshake response');
    }
    
    // Close the connection after receiving data
    setTimeout(() => client.destroy(), 1000);
});

client.on('close', function() {
    console.log('Connection closed');
    process.exit(0);
});

client.on('error', function(err) {
    console.log('Error:', err.message);
    process.exit(1);
});

// Exit after 10 seconds if nothing happens
setTimeout(() => {
    console.log('Timeout reached, exiting...');
    client.destroy();
    process.exit(1);
}, 10000);
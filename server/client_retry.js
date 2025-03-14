/**
 * This is a combined client that tries multiple WebSocket implementations
 * to establish a connection with the Godot WebSocket server.
 */

// Import libraries
const standardWs = require('ws');
const alternateClient = require('websocket').client;

console.log('==== WEBSOCKET CLIENT RETRY UTILITY ====');
console.log('Attempting to connect using multiple methods...');

// Try standard WebSocket first
console.log('\n[1/3] Attempting connection with standard WebSocket...');

const wsClient = new standardWs('ws://localhost:9080', {
  handshakeTimeout: 5000,
  perMessageDeflate: false
});

wsClient.on('open', () => {
  console.log('SUCCESS! Connected using standard WebSocket');
  
  console.log('Sending test message...');
  const message = JSON.stringify({
    type: 'test',
    params: { message: 'Hello from standard WebSocket!' },
    commandId: 'test-std-1'
  });
  
  wsClient.send(message);
});

wsClient.on('message', (data) => {
  console.log('Received response:', data.toString());
  console.log('Test successful! Closing connection...');
  wsClient.close();
  process.exit(0); // Success!
});

wsClient.on('error', (error) => {
  console.log('Standard WebSocket failed:', error.message);
  wsClient.terminate();
  
  // Try alternate implementation
  tryAlternateImplementation();
});

wsClient.on('close', () => {
  console.log('Standard WebSocket connection closed');
});

// Set timeout for first attempt
const timeoutStd = setTimeout(() => {
  if (wsClient.readyState !== standardWs.OPEN) {
    console.log('Standard WebSocket timed out');
    wsClient.terminate();
    tryAlternateImplementation();
  }
}, 6000);

function tryAlternateImplementation() {
  clearTimeout(timeoutStd);
  
  console.log('\n[2/3] Attempting connection with alternate WebSocket client...');
  
  const client = new alternateClient();
  
  client.on('connectFailed', (error) => {
    console.log('Alternate WebSocket connection failed:', error.toString());
    
    // Final attempt: raw socket
    tryRawImplementation();
  });
  
  client.on('connect', (connection) => {
    console.log('SUCCESS! Connected using alternate WebSocket client');
    
    connection.on('error', (error) => {
      console.log('Connection error:', error.toString());
      connection.close();
    });
    
    connection.on('close', () => {
      console.log('Alternate WebSocket connection closed');
    });
    
    connection.on('message', (message) => {
      if (message.type === 'utf8') {
        console.log('Received:', message.utf8Data);
        console.log('Test successful! Closing connection...');
        connection.close();
        process.exit(0); // Success!
      }
    });
    
    if (connection.connected) {
      console.log('Sending test message...');
      const message = JSON.stringify({
        type: 'test',
        params: { message: 'Hello from alternate WebSocket!' },
        commandId: 'test-alt-1'
      });
      
      connection.sendUTF(message);
    }
  });
  
  // Connect with alternate client
  client.connect('ws://localhost:9080');
  
  // Set timeout for second attempt
  setTimeout(() => {
    console.log('Alternate WebSocket timed out');
    tryRawImplementation();
  }, 6000);
}

function tryRawImplementation() {
  console.log('\n[3/3] Last resort: Attempting raw TCP socket with manual handshake...');
  
  const net = require('net');
  const crypto = require('crypto');
  
  // Generate a WebSocket key
  const key = crypto.randomBytes(16).toString('base64');
  console.log('WebSocket key:', key);
  
  // Create a TCP socket
  const socket = new net.Socket();
  
  socket.connect(9080, 'localhost', () => {
    console.log('TCP connected to server');
    
    // Send WebSocket handshake
    const handshake = 
        'GET / HTTP/1.1\r\n' +
        'Host: localhost:9080\r\n' +
        'Upgrade: websocket\r\n' +
        'Connection: Upgrade\r\n' +
        'Sec-WebSocket-Key: ' + key + '\r\n' +
        'Sec-WebSocket-Version: 13\r\n' +
        '\r\n';
    
    console.log('Sending handshake...');
    socket.write(handshake);
  });
  
  socket.on('data', (data) => {
    console.log('Received raw data from server:');
    console.log(data.toString());
    
    // Success if we got any response
    console.log('Got response from server!');
    socket.destroy();
    process.exit(0);
  });
  
  socket.on('close', () => {
    console.log('TCP socket closed');
    process.exit(1);
  });
  
  socket.on('error', (error) => {
    console.log('TCP socket error:', error.message);
    process.exit(1);
  });
  
  // Set final timeout
  setTimeout(() => {
    console.log('All connection attempts failed. Check server logs for details.');
    process.exit(1);
  }, 6000);
}

// Exit after 30 seconds (total timeout)
setTimeout(() => {
  console.log('Global timeout reached. Exiting...');
  process.exit(1);
}, 30000);
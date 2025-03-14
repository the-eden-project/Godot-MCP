/**
 * WebSocket Bridge Server for Godot MCP
 * 
 * This server acts as a middleman between the Node.js client and Godot.
 * It accepts WebSocket connections from the client and forwards messages
 * to Godot through TCPServer or any other mechanism.
 */

const WebSocket = require('ws');

// Create a WebSocket server
const wss = new WebSocket.Server({ port: 9080 });
console.log('WebSocket bridge server started on port 9080');

// Track connected clients
const clients = new Map();
let nextClientId = 1;

// Handle new client connections
wss.on('connection', (ws) => {
  const clientId = nextClientId++;
  clients.set(clientId, ws);
  
  console.log(`Client ${clientId} connected`);
  
  // Send welcome message
  ws.send(JSON.stringify({
    status: 'success',
    message: 'Connected to Godot WebSocket bridge'
  }));
  
  // Handle messages from client
  ws.on('message', (message) => {
    console.log(`Received from client ${clientId}:`, message.toString());
    
    try {
      const data = JSON.parse(message.toString());
      
      // Process the command (in a real scenario, this would communicate with Godot)
      console.log(`Processing command: ${data.type}`);
      
      // Send a response back to the client
      const response = {
        status: 'success',
        result: { 
          message: `Command ${data.type} processed`,
          timestamp: new Date().toISOString()
        },
        commandId: data.commandId || ''
      };
      
      ws.send(JSON.stringify(response));
      console.log(`Response sent to client ${clientId}`);
      
    } catch (error) {
      console.error('Error processing message:', error);
      ws.send(JSON.stringify({
        status: 'error',
        message: 'Invalid message format',
        error: error.message
      }));
    }
  });
  
  // Handle client disconnect
  ws.on('close', () => {
    console.log(`Client ${clientId} disconnected`);
    clients.delete(clientId);
  });
  
  // Handle errors
  ws.on('error', (error) => {
    console.error(`Error with client ${clientId}:`, error.message);
    clients.delete(clientId);
  });
});

// Handle server errors
wss.on('error', (error) => {
  console.error('WebSocket server error:', error.message);
});

console.log('WebSocket bridge server is running...');

// Handle process termination
process.on('SIGINT', () => {
  console.log('Shutting down WebSocket bridge server...');
  
  wss.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
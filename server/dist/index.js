import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import express from "express";
import cors from "cors";
import { z } from "zod";
import fs from "fs";
import path from "path";
// To store the currently open script information
let currentScript = {
    path: "",
    content: "",
    lastUpdated: new Date(),
};
// Map to store active SSE transports
const sseTransports = new Map();
// Create an MCP server
const server = new McpServer({
    name: "godot-script-server",
    version: "1.0.0",
});
// Add a resource for accessing the current script
server.resource("current-script", "godot://script/current", async (uri) => ({
    contents: [
        {
            uri: uri.href,
            text: currentScript.content,
            mimeType: "text/x-gdscript",
            name: path.basename(currentScript.path || "no-script-open.gd"),
        },
    ],
}));
// Add a tool to update the current script information
server.tool("update-current-script", "Updates info about the currently open script", {
    path: z.string().describe("Path to the script file"),
    content: z.string().describe("Content of the script"),
}, async ({ path: scriptPath, content }) => {
    currentScript = {
        path: scriptPath,
        content,
        lastUpdated: new Date(),
    };
    return {
        content: [
            {
                type: "text",
                text: `Script updated: ${path.basename(scriptPath)}`,
            },
        ],
    };
});
// Add a tool to list all scripts in a project directory
server.tool("list-project-scripts", "Lists all script files in a project directory", {
    projectDir: z.string().describe("Path to the Godot project directory"),
}, async ({ projectDir }) => {
    try {
        const scripts = await findScripts(projectDir);
        return {
            content: [
                {
                    type: "text",
                    text: JSON.stringify(scripts, null, 2),
                },
            ],
        };
    }
    catch (error) {
        return {
            content: [
                {
                    type: "text",
                    text: `Error listing scripts: ${error instanceof Error ? error.message : String(error)}`,
                },
            ],
            isError: true,
        };
    }
});
// Add a tool to read script content
server.tool("read-script", "Reads the content of a specific script", {
    scriptPath: z.string().describe("Path to the script file"),
}, async ({ scriptPath }) => {
    try {
        const content = await fs.promises.readFile(scriptPath, "utf8");
        return {
            content: [
                {
                    type: "text",
                    text: content,
                },
            ],
        };
    }
    catch (error) {
        return {
            content: [
                {
                    type: "text",
                    text: `Error reading script: ${error instanceof Error ? error.message : String(error)}`,
                },
            ],
            isError: true,
        };
    }
});
// Helper function to recursively find script files
async function findScripts(dir) {
    const scriptFiles = [];
    async function scanDirectory(currentDir) {
        const files = await fs.promises.readdir(currentDir, {
            withFileTypes: true,
        });
        for (const file of files) {
            const fullPath = path.join(currentDir, file.name);
            if (file.isDirectory()) {
                // Skip .git and other hidden directories
                if (!file.name.startsWith(".")) {
                    await scanDirectory(fullPath);
                }
            }
            else if (file.name.endsWith(".gd")) {
                scriptFiles.push(fullPath);
            }
        }
    }
    await scanDirectory(dir);
    return scriptFiles;
}
// Create Express app for HTTP communication with Godot
const app = express();
app.use(cors());
app.use(express.json());
// Endpoint for Godot to update the current script
app.post("/godot/current-script", (req, res) => {
    const { path: scriptPath, content } = req.body;
    currentScript = {
        path: scriptPath,
        content,
        lastUpdated: new Date(),
    };
    res.json({ success: true });
});
// Endpoint for Godot to get the currently active script
app.get("/godot/current-script", (req, res) => {
    res.json(currentScript);
});
// MCP SSE endpoint setup for HTTP transport
app.get("/mcp/sse", (req, res) => {
    const transport = new SSEServerTransport("/mcp/message", res);
    // Store the transport with its session ID
    sseTransports.set(transport.sessionId, transport);
    // Remove the transport when the connection is closed
    res.on("close", () => {
        sseTransports.delete(transport.sessionId);
        console.error(`SSE connection closed: ${transport.sessionId}`);
    });
    server.connect(transport).catch(console.error);
    console.error(`New SSE connection: ${transport.sessionId}`);
});
app.post("/mcp/message", (req, res) => {
    const sessionId = req.query.sessionId;
    const transport = sseTransports.get(sessionId);
    if (transport) {
        transport.handlePostMessage(req, res);
    }
    else {
        res
            .status(400)
            .json({ error: "No active transport found for this session" });
    }
});
// Main function to start everything
async function main() {
    try {
        // For command-line access via stdio
        if (process.argv.includes("--stdio")) {
            const stdioTransport = new StdioServerTransport();
            await server.connect(stdioTransport);
            console.error("Godot MCP Server running on stdio transport");
        }
        else {
            // Start HTTP server
            const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;
            app.listen(port, () => {
                console.error(`Godot MCP Server running on http://localhost:${port}`);
            });
        }
    }
    catch (error) {
        console.error("Error starting server:", error);
        process.exit(1);
    }
}
main();

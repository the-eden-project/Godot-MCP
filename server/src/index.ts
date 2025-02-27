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
server.tool(
  "update-current-script",
  "Updates info about the currently open script",
  {
    path: z.string().describe("Path to the script file"),
    content: z.string().describe("Content of the script"),
  },
  async ({ path: scriptPath, content }) => {
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
  }
);

// Add a tool to list all scripts in a project directory
server.tool(
  "list-project-scripts",
  "Lists all script files in a project directory",
  {
    projectDir: z.string().describe("Path to the Godot project directory"),
  },
  async ({ projectDir }) => {
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
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error listing scripts: ${
              (error as Error).message || String(error)
            }`,
          },
        ],
        isError: true,
      };
    }
  }
);

// Add a tool to read script content
server.tool(
  "read-script",
  "Reads the content of a specific script",
  {
    scriptPath: z.string().describe("Path to the script file"),
  },
  async ({ scriptPath }) => {
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
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error reading script: ${
              (error as Error).message || String(error)
            }`,
          },
        ],
        isError: true,
      };
    }
  }
);

// Helper function to recursively find script files
async function findScripts(dir: string): Promise<string[]> {
  const scriptFiles: string[] = [];

  async function scanDirectory(currentDir: string) {
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
      } else if (file.name.endsWith(".gd")) {
        scriptFiles.push(fullPath);
      }
    }
  }

  await scanDirectory(dir);
  return scriptFiles;
}

// Create a transport registry to store active transports
const activeTransports = new Map<string, ExtendedSSEServerTransport>();

// Extend the SSEServerTransport class with our additional functionality
class ExtendedSSEServerTransport extends SSEServerTransport {
  initialize(req: express.Request): string {
    const sessionId =
      (req.query.sessionId as string) ||
      Math.random().toString(36).substring(2, 15);
    activeTransports.set(sessionId, this);
    return sessionId;
  }

  static getTransportForRequest(
    req: express.Request
  ): ExtendedSSEServerTransport | undefined {
    const sessionId = req.query.sessionId as string;
    return sessionId ? activeTransports.get(sessionId) : undefined;
  }
}

// Main function to start everything
async function main() {
  // Detect if running in stdio mode (which is how Claude Desktop runs it)
  const isStdioMode =
    process.argv.includes("--stdio") ||
    !process.stdout.isTTY ||
    process.env.MCP_TRANSPORT === "stdio";

  try {
    if (isStdioMode) {
      // When running in stdio mode, only use stdio transport
      console.error("Godot MCP Server running in stdio mode");
      const stdioTransport = new StdioServerTransport();
      await server.connect(stdioTransport);
    } else {
      // When running as standalone, use HTTP server
      console.error("Godot MCP Server running in HTTP mode");

      // Create Express app for HTTP communication
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
        const transport = new ExtendedSSEServerTransport("/mcp/message", res);
        const sessionId = transport.initialize(req);
        res.setHeader("X-Session-ID", sessionId);
        server.connect(transport).catch(console.error);
      });

      app.post("/mcp/message", (req, res) => {
        const transport =
          ExtendedSSEServerTransport.getTransportForRequest(req);
        if (transport) {
          transport.handlePostMessage(req, res);
        } else {
          res
            .status(400)
            .json({ error: "No active transport found for this session" });
        }
      });

      // Use a different port if specified via environment
      const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;

      try {
        app.listen(port, () => {
          console.error(`Godot MCP Server running on http://localhost:${port}`);
        });
      } catch (error) {
        console.error(`Failed to start HTTP server on port ${port}:`, error);
        console.error("The server will continue to work in stdio mode only.");
      }
    }
  } catch (error) {
    console.error("Error starting server:", error);
    process.exit(1);
  }
}

main();

# SwiftUI Pro MCP Server

A compiled, zero-dependency [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that exposes the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson as MCP tools — usable by any MCP-compatible client.

Because it is a compiled binary (built with [Zig](https://ziglang.org)), it requires no runtime, no package manager, and no interpreter. All skill content is embedded at compile time.

---

## Building

Requires [Zig 0.14](https://ziglang.org/download/).

```sh
zig build -Doptimize=ReleaseSafe
```

binary lands at: zig-out/bin/swiftui-mcp-server

# Cross-compilation
Zig makes cross-compilation trivial:

# sh
## Apple Silicon Mac
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe

## Intel Mac
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe

## Linux (x86-64)
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

## Windows (x86-64)
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe


# Available Tools
| --- | ---- | ---- |
| Tool | Arguments | Description |
| list_swiftui_topics | none | Returns all available reference topic names |
| get_swiftui_skill | none | Returns the full skill definition (review process, output format, core instructions) |
| get_swiftui_reference | topic (string) | Returns the reference guide for a specific topic |

Valid topic values: accessibility, api, data, design, hygiene, navigation, performance, swift, views

# Client Configuration
## Claude Desktop
Edit ~/Library/Application Support/Claude/claude_desktop_config.json (macOS) or %APPDATA%\Claude\claude_desktop_config.json (Windows):

```
JSON
{
  "mcpServers": {
    "swiftui-pro": {
      "command": "/path/to/swiftui-mcp-server"
    }
  }
}
```

# VS Code (GitHub Copilot Chat)

Add to .vscode/mcp.json in your workspace:

```
JSON
{
  "servers": {
    "swiftui-pro": {
      "type": "stdio",
      "command": "/path/to/swiftui-mcp-server"
    }
  }
}
```

# Zed

Edit ~/.config/zed/settings.json:

```
JSON
{
  "context_servers": {
    "swiftui-pro": {
      "command": {
        "path": "/path/to/swiftui-mcp-server",
        "args": []
      }
    }
  }
}
```

# Cursor

Edit ~/.cursor/mcp.json:

```
JSON
{
  "mcpServers": {
    "swiftui-pro": {
      "command": "/path/to/swiftui-mcp-server"
    }
  }
}
```

# How It Works

The server speaks MCP over stdio using newline-delimited JSON-RPC 2.0. All Markdown content from the SwiftUI Pro skill is embedded into the binary at compile time via Zig's @embedFile — no files need to be present at runtime.

All diagnostic output goes to stderr; stdout is used exclusively for JSON-RPC responses.

# Attribution

Skill content is from twostraws/SwiftUI-Agent-Skill by Paul Hudson, licensed under the MIT License.

This MCP server wrapper is also MIT licensed.

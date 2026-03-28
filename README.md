# SwiftUI Pro MCP Server

A **compiled, zero-dependency MCP server** that exposes the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson over the [Model Context Protocol](https://modelcontextprotocol.io/) (stdio JSON-RPC 2.0).

All skill content is **embedded at compile time** — the resulting binary is fully self-contained and works with any MCP-compatible tool.

---

## Building

Requires [Zig 0.14](https://ziglang.org/download/).

```sh
zig build -Doptimize=ReleaseSafe
# Binary: ./zig-out/bin/swiftui-mcp-server
```

### Cross-compilation

Zig makes cross-compilation trivial — no toolchain setup required:

```sh
# Apple Silicon Mac
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe

# Intel Mac
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe

# Linux x86-64
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

# Windows x86-64
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
```

---

## Available Tools

| Tool | Arguments | Description |
|---|---|---|
| `list_swiftui_topics` | _(none)_ | Returns the list of all available reference topic names |
| `get_swiftui_skill` | _(none)_ | Returns the full SwiftUI Pro skill definition (review process, output format, core instructions) |
| `get_swiftui_reference` | `topic` (string) | Returns the reference guide for one topic: `accessibility`, `api`, `data`, `design`, `hygiene`, `navigation`, `performance`, `swift`, or `views` |

---

## Client Configuration

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "swiftui-pro": {
      "command": "/path/to/swiftui-mcp-server"
    }
  }
}
```

### VS Code (Copilot Chat)

Add to `.vscode/mcp.json` in your workspace, or to your user `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "swiftui-pro": {
        "type": "stdio",
        "command": "/path/to/swiftui-mcp-server"
      }
    }
  }
}
```

### Zed

Edit `~/.config/zed/settings.json`:

```json
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

### Cursor

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "swiftui-pro": {
      "command": "/path/to/swiftui-mcp-server"
    }
  }
}
```

---

## How It Works

- **Transport:** MCP stdio (newline-delimited JSON-RPC 2.0 on stdin/stdout)
- **Content:** All 9 reference Markdown files and the main skill file are embedded via `@embedFile` at compile time — no file system access at runtime
- **Logging:** All diagnostic output goes to stderr; stdout is exclusively JSON-RPC
- **Protocol version:** `2024-11-05`

---

## Attribution

Skill content sourced from [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by **Paul Hudson**, licensed under the MIT License.

This MCP server wrapper is also MIT licensed.
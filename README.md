# SwiftUI Pro MCP Server

A compiled, zero-dependency [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that exposes the [SwiftUI Pro agent skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson as MCP tools — usable by any MCP-compatible client.

Because it is a compiled binary (built with [Zig](https://ziglang.org)), it requires no runtime, no package manager, and no interpreter. All skill content is embedded at compile time.

---

## Building

Requires [Zig 0.14](https://ziglang.org/download/).

```sh
zig build -Doptimize=ReleaseSafe
# binary lands at: zig-out/bin/swiftui-mcp-server

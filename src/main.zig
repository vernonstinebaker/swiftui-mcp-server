//! SwiftUI Pro MCP Server
//! A compiled MCP (Model Context Protocol) server that exposes the SwiftUI Pro
//! agent skill content over stdio JSON-RPC 2.0.
//!
//! Compatible with any MCP client: Claude Desktop, VS Code, Zed, Cursor, etc.
//! Build: zig build
//! Run:   ./zig-out/bin/swiftui-mcp-server

const std = @import("std");

// Embed all skill content at compile time - binary is fully self-contained.
const skill_main = @embedFile("skills/SKILL.md");
const skill_accessibility = @embedFile("skills/accessibility.md");
const skill_api = @embedFile("skills/api.md");
const skill_data = @embedFile("skills/data.md");
const skill_design = @embedFile("skills/design.md");
const skill_hygiene = @embedFile("skills/hygiene.md");
const skill_navigation = @embedFile("skills/navigation.md");
const skill_performance = @embedFile("skills/performance.md");
const skill_swift = @embedFile("skills/swift.md");
const skill_views = @embedFile("skills/views.md");

const PROTOCOL_VERSION = "2024-11-05";
const SERVER_NAME = "swiftui-mcp-server";
const SERVER_VERSION = "1.0.0";
const MAX_LINE_SIZE = 1024 * 1024; // 1 MB

/// Look up a reference file by topic name.
fn topicContent(topic: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, topic, "accessibility")) return skill_accessibility;
    if (std.mem.eql(u8, topic, "api")) return skill_api;
    if (std.mem.eql(u8, topic, "data")) return skill_data;
    if (std.mem.eql(u8, topic, "design")) return skill_design;
    if (std.mem.eql(u8, topic, "hygiene")) return skill_hygiene;
    if (std.mem.eql(u8, topic, "navigation")) return skill_navigation;
    if (std.mem.eql(u8, topic, "performance")) return skill_performance;
    if (std.mem.eql(u8, topic, "swift")) return skill_swift;
    if (std.mem.eql(u8, topic, "views")) return skill_views;
    return null;
}

/// Write a JSON-escaped string value (without surrounding quotes).
fn writeEscaped(writer: anytype, s: []const u8) !void {
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            0x00...0x08, 0x0B, 0x0C, 0x0E...0x1F => {
                try writer.print("\\u{x:0>4}", .{c});
            },
            else => try writer.writeByte(c),
        }
    }
}

/// Write a complete JSON-RPC 2.0 success response followed by a newline.
/// `id_raw` is the verbatim JSON id value (e.g. "1", "\"abc\"", "null").
/// `result_json` is the pre-formatted JSON object/string for the result field.
fn writeSuccess(writer: anytype, id_raw: []const u8, result_json: []const u8) !void {
    try writer.print("{{\"jsonrpc\":\"2.0\",\"id\":{s},\"result\":{s}}}\n", .{ id_raw, result_json });
}

/// Write a complete JSON-RPC 2.0 error response followed by a newline.
fn writeError(writer: anytype, id_raw: []const u8, code: i32, message: []const u8) !void {
    try writer.print("{{\"jsonrpc\":\"2.0\",\"id\":{s},\"error\":{{\"code\":{d},\"message\":\"", .{ id_raw, code });
    try writeEscaped(writer, message);
    try writer.writeAll("\"}}\n");
}

/// Write a text content result: {"content":[{"type":"text","text":"<escaped>"}]}
fn writeTextResult(writer: anytype, id_raw: []const u8, text: []const u8) !void {
    try writer.print("{{\"jsonrpc\":\"2.0\",\"id\":{s},\"result\":{{\"content\":[{{\"type\":\"text\",\"text\":\"", .{id_raw});
    try writeEscaped(writer, text);
    try writer.writeAll("\"]}}}}\n");
}

/// Extract the raw JSON value for a given key from a flat JSON object string.
/// Returns the verbatim value slice (e.g. `1`, `"hello"`, `null`).
/// Only handles top-level keys, not nested objects.
fn extractJsonValue(json: []const u8, key: []const u8) ?[]const u8 {
    // Build search pattern: "key":
    var key_pattern_buf: [128]u8 = undefined;
    const key_pattern = std.fmt.bufPrint(&key_pattern_buf, "\"{s}\":", .{key}) catch return null;

    const key_pos = std.mem.indexOf(u8, json, key_pattern) orelse return null;
    var pos = key_pos + key_pattern.len;

    // Skip whitespace
    while (pos < json.len and (json[pos] == ' ' or json[pos] == '\t')) {
        pos += 1;
    }
    if (pos >= json.len) return null;

    const start = pos;
    if (json[pos] == '\"') {
        // String value - scan for closing quote, respecting escapes
        pos += 1;
        while (pos < json.len) {
            if (json[pos] == '\\') {
                pos += 2;
            } else if (json[pos] == '\"') {
                pos += 1;
                break;
            } else {
                pos += 1;
            }
        }
        return json[start..pos];
    } else if (json[pos] == '{' or json[pos] == '[') {
        // Object or array - find matching closer
        const opener = json[pos];
        const closer: u8 = if (opener == '{') '}' else ']';
        var depth: usize = 1;
        pos += 1;
        while (pos < json.len and depth > 0) {
            if (json[pos] == '\"') {
                pos += 1;
                while (pos < json.len) {
                    if (json[pos] == '\\') {
                        pos += 2;
                    } else if (json[pos] == '\"') {
                        pos += 1;
                        break;
                    } else {
                        pos += 1;
                    }
                }
            } else if (json[pos] == opener) {
                depth += 1;
                pos += 1;
            } else if (json[pos] == closer) {
                depth -= 1;
                pos += 1;
            } else {
                pos += 1;
            }
        }
        return json[start..pos];
    } else {
        // Number, boolean, or null - scan until delimiter
        while (pos < json.len) {
            const ch = json[pos];
            if (ch == ',' or ch == '}' or ch == ']' or ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r') {
                break;
            }
            pos += 1;
        }
        return json[start..pos];
    }
}

/// Extract a string value (unquoted content) from a JSON string token like \"hello\".
fn unquoteJsonString(s: []const u8) []const u8 {
    if (s.len >= 2 and s[0] == '\"' and s[s.len - 1] == '\"') {
        return s[1 .. s.len - 1];
    }
    return s;
}

/// Determine if this JSON message is a notification (has "method" but no "id").
fn isNotification(json: []const u8) bool {
    // Notifications have a "method" field but no "id" field.
    const has_method = std.mem.indexOf(u8, json, "\"method\"") != null;
    const has_id = std.mem.indexOf(u8, json, "\"id\"") != null;
    return has_method and !has_id;
}

/// Extract the topic string from a tools/call params.arguments object.
/// Looks for: "arguments":{"topic":"<value>"}
fn extractTopic(json: []const u8) ?[]const u8 {
    const args_val = extractJsonValue(json, "arguments") orelse return null;
    const topic_val = extractJsonValue(args_val, "topic") orelse return null;
    return unquoteJsonString(topic_val);
}

/// Extract the tool name from params.name.
fn extractToolName(json: []const u8) ?[]const u8 {
    // params is an object; find it, then find "name" within it
    const params_val = extractJsonValue(json, "params") orelse return null;
    const name_val = extractJsonValue(params_val, "name") orelse return null;
    return unquoteJsonString(name_val);
}

fn handleInitialize(writer: anytype, id_raw: []const u8) !void {
    try writeSuccess(writer, id_raw,
        \\{"protocolVersion":"2024-11-05","capabilities":{"tools":{},"serverInfo":{"name":"swiftui-mcp-server","version":"1.0.0"}}
    );
}

fn handleToolsList(writer: anytype, id_raw: []const u8) !void {
    try writeSuccess(writer, id_raw,
        \\{"tools":[{"name":"list_swiftui_topics","description":"List all available SwiftUI Pro reference topics.","inputSchema":{"type":"object","properties":{}}},{"name":"get_swiftui_skill","description":"Get the full SwiftUI Pro skill definition including review process and output format.","inputSchema":{"type":"object","properties":{}}},{"name":"get_swiftui_reference","description":"Get the SwiftUI Pro reference guide for a specific topic.","inputSchema":{"type":"object","properties":{"topic":{"type":"string","description":"One of: accessibility, api, data, design, hygiene, navigation, performance, swift, views"}},"required":["topic"]}}]}
    );
}

fn handleToolsCall(writer: anytype, id_raw: []const u8, json: []const u8, stderr: anytype) !void {
    const tool_name = extractToolName(json) orelse {
        try writeError(writer, id_raw, -32602, "Missing params.name");
        return;
    };

    try stderr.print("[swiftui-mcp] tool call: {s}\n", .{tool_name});

    if (std.mem.eql(u8, tool_name, "list_swiftui_topics")) {
        try writeTextResult(writer, id_raw, "accessibility\napi\ndata\ndesign\nhygiene\nnavigation\nperformance\nswift\nviews");
    } else if (std.mem.eql(u8, tool_name, "get_swiftui_skill")) {
        try writeTextResult(writer, id_raw, skill_main);
    } else if (std.mem.eql(u8, tool_name, "get_swiftui_reference")) {
        const topic = extractTopic(json) orelse {
            try writeError(writer, id_raw, -32602, "Missing arguments.topic");
            return;
        };
        const content = topicContent(topic) orelse {
            var msg_buf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&msg_buf, "Unknown topic: {s}", .{topic}) catch "Unknown topic";
            try writeError(writer, id_raw, -32602, msg);
            return;
        };
        try writeTextResult(writer, id_raw, content);
    } else {
        try writeError(writer, id_raw, -32601, "Unknown tool");
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stderr.print("[swiftui-mcp] server started (protocol {s})\n", .{PROTOCOL_VERSION});

    // Buffer for reading lines
    var line_buf = std.ArrayList(u8).init(allocator);
    defer line_buf.deinit();

    while (true) {
        line_buf.clearRetainingCapacity();

        // Read one line (newline-delimited JSON-RPC)
        stdin.streamUntilDelimiter(line_buf.writer(), '\n', MAX_LINE_SIZE) catch |err| {
            if (err == error.EndOfStream) break;
            if (err == error.StreamTooLong) {
                try stderr.writeAll("[swiftui-mcp] line too long, skipping\n");
                continue;
            }
            return err;
        };

        const line = std.mem.trim(u8, line_buf.items, " \t\r\n");
        if (line.len == 0) continue;

        try stderr.print("[swiftui-mcp] recv: {s}\n", .{line});

        // Skip notifications (no "id" field)
        if (isNotification(line)) {
            try stderr.writeAll("[swiftui-mcp] notification, skipping\n");
            continue;
        }

        // Extract id - default to null if missing
        const id_raw = extractJsonValue(line, "id") orelse "null";
        const method_val = extractJsonValue(line, "method") orelse {
            try writeError(stdout, id_raw, -32600, "Invalid Request: missing method");
            continue;
        };
        const method = unquoteJsonString(method_val);

        try stderr.print("[swiftui-mcp] method: {s}\n", .{method});

        if (std.mem.eql(u8, method, "initialize")) {
            try handleInitialize(stdout, id_raw);
        } else if (std.mem.eql(u8, method, "tools/list")) {
            try handleToolsList(stdout, id_raw);
        } else if (std.mem.eql(u8, method, "tools/call")) {
            try handleToolsCall(stdout, id_raw, line, stderr);
        } else if (std.mem.eql(u8, method, "ping")) {
            try writeSuccess(stdout, id_raw, "{}");
        } else {
            try writeError(stdout, id_raw, -32601, "Method not found");
        }
    }

    try stderr.writeAll("[swiftui-mcp] stdin closed, shutting down\n");
}
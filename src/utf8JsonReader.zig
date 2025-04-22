const std = @import("std");
const print = std.debug.print;

pub fn hello() !void {
    print("Hello there", .{});
}

const JsonTokenType = enum { none, start_object, end_object, start_array, end_array, property, comment, string, number, true, false, null, undefined };

const start_object = '{';
const end_object = '}';
const start_array = '[';
const end_array = ']';
const comment = '/';
const quote = '"';

const ReadResultTag = enum { ok, need_more };
const ReadResult = union(ReadResultTag) { ok: u8, need_more: void };

pub fn readNext(buffer: []const u8) !ReadResult {
    var index: usize = 0;
    while (index < buffer.len) {
        print("read next: {c}\n", .{buffer[index]});
        index += 1;
    }

    print("leaving...\n", .{});

    return ReadResult{ .ok = 'y' };
}

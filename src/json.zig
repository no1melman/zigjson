const std = @import("std");
const print = std.debug.print;
const mem = std.mem;

const JsonTokenType = enum { none, start_object, end_object, start_array, end_array, property, comment, string, number, true, false, null, undefined };

const start_object = '{';
const end_object = '}';
const start_array = '[';
const end_array = ']';
const comment = '/';
const quote = '"';

const ReadResultTag = enum { ok, need_more };
const ReadResult = union(ReadResultTag) { ok: u8, need_more: void };

const ReaderPosition = struct { index: usize = 0 };

const Utf8JsonReader = struct {
    position: ReaderPosition,
    buffer: *const []u8,
    tokenType: JsonTokenType = .none,

    pub fn read_next(self: *Utf8JsonReader) bool {
        if (self.position.index < self.buffer.len) {
            print("read next: {c}\n", .{self.buffer.*[self.position.index]});

            // need to discern the actual token read...
            self.tokenType = .start_object;

            self.position.index += 1;
            return true;
        } else {
            return false;
        }
    }
};

pub fn create_reader(buffer: *const []u8) !Utf8JsonReader {
    const position = ReaderPosition{ .index = 0 };
    const reader = Utf8JsonReader{ .position = position, .buffer = buffer };

    return reader;
}

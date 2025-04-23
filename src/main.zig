const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;
const json = @import("json.zig");

pub fn main() !void {
    print("hello there", .{});

    const file = try std.fs.cwd().openFile("compile_commands.json", .{});
    defer file.close();

    var buffer: [30]u8 = [_]u8{0} ** 30;
    var read_bytes: usize = undefined;
    var should_continue: bool = true;


    while (read_bytes > 0 and should_continue) {
        read_bytes = try file.read(&buffer);

        const utf8_reader = try json.create_reader(&buffer);
        _ = utf8_reader.position.index;

        if (read_bytes == 0) {
            break;
        }

        const buffer_slice = buffer[0..read_bytes];
        const result = try json.read_next(buffer_slice);

        should_continue = switch (result) {
            .ok => false,
            .need_more => true
        };

        print("Buffer: {s} ({})\n", .{ buffer[0..read_bytes], read_bytes });
    }

    print("Done\n", .{});
}

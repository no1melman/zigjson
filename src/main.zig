const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;
const json = @import("json.zig");

pub fn main() !void {
    print("hello there\n", .{});

    const file = try std.fs.cwd().openFile("compile_commands.json", .{});
    defer file.close();

    var buffer: [30]u8 = [_]u8{0} ** 30;
    var read_bytes: usize = undefined;

    while (read_bytes > 0) {
        read_bytes = try file.read(&buffer);

        if (read_bytes == 0) {
            break;
        }

        const buffer_slice = buffer[0..read_bytes];
        var utf8_reader = try json.create_reader(&buffer_slice);
        while (utf8_reader.read_next()) {
            const readToken = utf8_reader.tokenType;

            print("Read: {}\n", .{readToken});

            break;
        }
        break;
    }

    print("Done\n", .{});
}

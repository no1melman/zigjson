const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;

pub fn main() !void {

    print("hello there", .{});


    const file = try std.fs.cwd().openFile("build.ps1", .{});
    defer file.close();

    var buffer: [30]u8 = [_]u8{0} ** 30;
    var read_bytes: usize = undefined;
    while (read_bytes > 0) {
        read_bytes = try file.read(&buffer);

        if (read_bytes == 0) {
            break;
        }

        print("Buffer: {s} ({})\n", .{buffer[0..read_bytes], read_bytes});
    }

    print("Done\n", .{});
}



const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;
const json = @import("json.zig");

pub fn main() !void {
    print("hello there\n", .{});

    const file = try std.fs.cwd().openFile("compile_commands.json", .{});
    defer file.close();

    // Setup fallback allocator for the stack allocator
    var fallback_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer fallback_arena.deinit();

    const fallback_allocator = fallback_arena.allocator();

    // Setup the stack fallback allocator for use in the utf8 reader
    var stack_fallback = std.heap.stackFallback(64596, fallback_allocator);
    const stack_allocator = stack_fallback.get();

    var buffer: [30]u8 = [_]u8{0} ** 30;
    var read_bytes: usize = undefined;

    while (read_bytes > 0) {
        read_bytes = try file.read(&buffer);

        if (read_bytes == 0) {
            break;
        }

        const buffer_slice = buffer[0..read_bytes];
        var utf8_reader = try json.CreateReader(&buffer_slice, stack_allocator);
        while (try utf8_reader.readNext()) {
            const read_token = utf8_reader.token_type;

            print("Read: {}\n", .{read_token});
        }
    }

    print("Done\n", .{});
}

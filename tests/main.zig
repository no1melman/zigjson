
const std = @import("std");


test "while condition" {
    var readAmount: usize = undefined;
    while (readAmount > 1) {
        readAmount = 10;
        try std.testing.expect(1 == 1);
        readAmount = 0;
        std.debug.print("got here\n", .{});
    }
    
    try std.testing.expect(readAmount == 0);
}

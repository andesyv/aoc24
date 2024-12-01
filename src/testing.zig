const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, Advent of Code!\n", .{});
}

// test "slice testing" {
//     const arr = [_]u32{ 1, 3, 4 };
//     const slice = arr[0.. :4];
//     try std.testing.expect(slice.len == 4);
// }

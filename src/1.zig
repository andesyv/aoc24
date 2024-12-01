const std = @import("std");

const NumberLists = struct {
    lhs: std.ArrayList(u32),
    rhs: std.ArrayList(u32),

    pub fn deinit(self: @This()) void {
        self.lhs.deinit();
        self.rhs.deinit();
    }

};

fn parse(allocator: std.mem.Allocator, input: []const u8) (std.fmt.ParseIntError||std.mem.Allocator.Error)!NumberLists {
    var lhs = std.ArrayList(u32).init(allocator);
    var rhs = std.ArrayList(u32).init(allocator);

    var line_it = std.mem.tokenizeScalar(u8, input, '\n');
    var left = true;
    while (line_it.next()) |line| {
        var token_it = std.mem.tokenizeScalar(u8, line, ' ');
        while (token_it.next()) |num| {
            const n = try std.fmt.parseInt(u32, num, 0);
            try (if (left) lhs else rhs).append(n);
            left = !left;
        }
    }

    return .{
        .lhs = lhs,
        .rhs = rhs,
    };
}

fn findSumOfNumbersIncreasingInSize(input: NumberLists) u32 {
    std.mem.sort(u32, input.lhs.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, input.rhs.items, {}, comptime std.sort.asc(u32));
    var sum: u32 = 0;
    for (input.lhs.items, input.rhs.items) |lhs, rhs| {
        sum += @max(lhs, rhs) - @min(lhs, rhs);
    }
    return sum;
}

pub fn main() void {
    // const input = @embedFile( "../inputs/1.txt");
    const res = @import("inputs");

    const allocator = std.heap.page_allocator;
    const parsed = parse(allocator, res.input_1) catch |err| {
        std.debug.panic("Parsing input failed with the following error: {any}\n", .{err});
    };
    defer parsed.deinit();

    const stdout = std.io.getStdOut();
    std.fmt.format(stdout.writer(), "Sum of numbers in increasing size: {d}\n", .{findSumOfNumbersIncreasingInSize(parsed)}) catch |err| {
        std.debug.panic("Parsing input failed with the following error: {any}\n", .{err});
    };
}

const example_input =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

const test_allocator = std.testing.allocator;

test "parse test" {
    const sut = try parse(test_allocator , example_input);
    defer sut.deinit();
    const expected = NumberLists {
        // Zig doesn't have a Container::from() helper yet. So creating heap-allocated memory is a bit of a hassle:
        // https://github.com/ziglang/zig/issues/11479
        .lhs = blk: {
            var list = std.ArrayList(u32).init(test_allocator);
            try list.appendSlice(&[_]u32{ 3, 4, 2, 1, 3, 3 });
            break :blk list;
        },
        .rhs = blk: {
            var list = std.ArrayList(u32).init(test_allocator);
            try list.appendSlice(&[_]u32{ 4, 3, 5, 3, 9, 3 });
            break :blk list;
        },
    };
    defer expected.deinit();

    try std.testing.expectEqualSlices(u32, expected.lhs.items, sut.lhs.items);
    try std.testing.expectEqualSlices(u32, expected.rhs.items, sut.rhs.items);
}

test "sum of numbers increasing in size" {
    const sut = try parse(test_allocator, example_input);
    defer sut.deinit();

    const result = findSumOfNumbersIncreasingInSize(sut);
    try std.testing.expectEqual(11, result);
}

const std = @import("std");
const ArrayList = std.ArrayList;

const Report = struct {
    levels: ArrayList(u32),

    fn deinit(self: @This()) void {
        self.levels.deinit();
    }

    fn slice(self: @This()) []u32 {
        return self.levels.items;
    }
};

// Now this is my current problem with Zig:
// Using nested structures becomes increasingly complex as Zig doesn't have constructors and destructors.
// Ideally I wanted to just use ArrayList(Report), but needed to wrap it into another struct purely to
// be able to deinit it as Zig's ArrayList doesn't do this itself.
const Reports = struct {
    reports: ArrayList(Report),

    fn deinit(self: @This()) void {
        for (self.reports.items) |report| {
            report.deinit();
        }

        self.reports.deinit();
    }

    fn len(self: @This()) usize {
        return self.reports.items.len;
    }

    fn slice(self: @This()) []Report {
        return self.reports.items;
    }
};

fn parse(allocator: std.mem.Allocator, input: []const u8) (std.fmt.ParseIntError||std.mem.Allocator.Error)!Reports {
    var reports = ArrayList(Report).init(allocator);

    var line_it = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        var levels = try ArrayList(u32).initCapacity(allocator, 10);
        var token_it = std.mem.tokenizeScalar(u8, line, ' ');
        while (token_it.next()) |num| {
            const n = try std.fmt.parseInt(u32, num, 0);
            try levels.append(n);
        }
        if (levels.items.len == 0) {
            defer levels.deinit();
        }

        try reports.append(Report{ .levels = levels });
    }

    return Reports{ .reports = reports };
}

const ClimbingMode = enum { Increasing, Decreasing };

fn isSafeDiff(diff: u32) bool {
    return switch (diff) {
        1...3 => true,
        else => false,
    };
}

fn isSafeLevelRecursiveCase(levels: []u32, mode: ClimbingMode) bool {
    if (levels.len < 2) {
        return true;
    }

    const a = levels[0];
    const b = levels[1];
    const current_safe = switch (mode) {
        ClimbingMode.Increasing => a < b and isSafeDiff(b - a),
        ClimbingMode.Decreasing => a > b and isSafeDiff(a - b),
    };
    return current_safe and isSafeLevelRecursiveCase(levels[1..], mode);
}

fn isSafeLevel(levels: []u32) bool {
    if (levels.len < 2) {
        return true;
    }

    const a = levels[0];
    const b = levels[1];
    return isSafeLevelRecursiveCase(levels, if (a < b) ClimbingMode.Increasing else ClimbingMode.Decreasing);
}

fn countSafeLevels(reports: Reports) u32 {
    var count: u32 = 0;
    for (reports.slice()) |report| {
        if (isSafeLevel(report.slice())) {
            count += 1;
        }
    }
    return count;
}

pub fn main() void {
    const res = @import("inputs");
    const allocator = std.heap.page_allocator;
    const reports = parse(allocator, res.input_2) catch |err| {
        std.debug.panic("Parsing input failed with the following error: {any}\n", .{err});
    };

    const stdout = std.io.getStdOut();
    std.fmt.format(stdout.writer(), "Count of safe reports: {d}\n", .{countSafeLevels(reports)}) catch |err| {
        std.debug.panic("Writing to stdout failed with the following error: {any}\n", .{err});
    };
}

const example_input =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

const test_allocator = std.testing.allocator;

fn createReports(allocator: std.mem.Allocator, values: []const []const u32) std.mem.Allocator.Error!Reports {
    var list = ArrayList(Report).init(allocator);
    for (values) |levels| {
        var levels_list = ArrayList(u32).init(allocator);
        try levels_list.appendSlice(levels);
        try list.append(Report{ .levels = levels_list });
    }
    return Reports{ .reports = list };
}

test "parse reports" {
    const sut = try parse(test_allocator, example_input);
    defer sut.deinit();

    const expected = try createReports(test_allocator, &.{
        &.{ 7, 6, 4, 2, 1 },
        &.{ 1, 2, 7, 8, 9 },
        &.{ 9, 7, 6, 2, 1 },
        &.{ 1, 3, 2, 4, 5 },
        &.{ 8, 6, 4, 4, 1 },
        &.{ 1, 3, 6, 7, 9 },
    });
    defer expected.deinit();

    try std.testing.expectEqual(expected.len(), sut.len());
    for (expected.slice(), sut.slice(), 0..) |e, a, i| {
        std.testing.expectEqualSlices(u32, e.levels.items, a.levels.items) catch |err| {
            std.debug.print("Mismached structs in level {d}. \nExpected: {any}, \nActual: {any}\n", .{ i, e.levels.items, a.levels.items });
            return err;
        };
    }
}

test "safe levels in example" {
    const sut = try parse(test_allocator, example_input);
    defer sut.deinit();
    
    try std.testing.expectEqual(2, countSafeLevels(sut));
}

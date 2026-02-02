const std = @import("std");

pub const Clock = struct {
    current_time: u64,
    dilation_factor: u64,

    pub fn init() Clock {
        return .{
            .current_time = 0,
            .dilation_factor = 1_000, // clock runs at x1000
        };
    }

    pub fn advance(self: *Clock, duration: u64) void {
        self.current_time += duration;
    }

    pub fn now(self: *const Clock) u64 {
        return self.current_time;
    }

    pub fn hasTimedOut(self: *const Clock, deadline: u64) bool {
        return self.current_time >= deadline;
    }

    pub fn formatTime(self: *const Clock, buf: []u8) []const u8 {
        const ms = self.current_time / 1_000_000;
        const res = std.fmt.bufPrint(buf, "T+{d}ms", .{ms}) catch "T+???ms";

        return res;
    }
};

test "clock advances deterministically" {
    var c = Clock.init();
    try std.testing.expectEqual(@as(u64, 0), c.now());

    // advance 1ms
    c.advance(1_000_000);
    try std.testing.expectEqual(@as(u64, 1_000_000), c.now());

    // advance 5ms
    c.advance(5_000_000);
    try std.testing.expectEqual(@as(u64, 6_000_000), c.now());
}

const std = @import("std");
const Bank = @import("bank.zig").Bank;
const Clock = @import("clock.zig").Clock;
const DeterministicRNG = @import("prng.zig").DeterministicRNG;

const stdout = std.io.getStdOut().writer();

const cfg = struct {
    const accounts_count: u32 = 65_535;
    const balance_initial: u64 = 10_000;
    const universe_count: u64 = 10_000;
    const universe_transfer_count: u32 = 100;
    const injection_rate: f64 = 0.35;
    const chaos_enabled: bool = true;
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("Simulator…\n", .{});

    try universe(allocator, cfg.chaos_enabled); // tmp
}

pub fn universe(allocator: std.mem.Allocator, chaos_enabled: bool) !void {
    try stdout.print("Simulating a new universe\n", .{});

    var clock = Clock.init();
    var bank = Bank.init(allocator, &clock);
    defer bank.deinit();
    bank.chaos_enabled = chaos_enabled;

    var i: u32 = 0;
    while (i < cfg.accounts_count) : (i += 1) {
        try bank.createAccount(i, cfg.balance_initial);
    }
    try stdout.print("Seeded {d} accounts for universe\n", .{i});
}

const Universe = struct {
    seed: u64,
    success: bool,
};

const ErrorType = enum {
    UNDEFINED,
    NEGATIVE_BALANCE,
    CONSTRAINT_VIOLATION,
    UNHANDLED_EXCEPTION,
};

const std = @import("std");
const Bank = @import("bank.zig").Bank;
const Clock = @import("clock.zig").Clock;
const DeterministicRNG = @import("prng.zig").DeterministicRNG;
const Scheduler = @import("scheduler.zig").Scheduler;
const EventPayload = @import("scheduler.zig").EventPayload;

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

    var permutations_tested: u64 = 0;

    const genesis: u64 = 131;
    var seed = genesis;
    while (seed < genesis + cfg.universe_count) : (seed += 1) {
        permutations_tested += 1;
        _ = try universe(allocator, seed, cfg.chaos_enabled);

        if (permutations_tested % 1000 == 0) {
            try stdout.print("tested {d} variants\n", .{permutations_tested});
        }
    }
}

pub fn universe(allocator: std.mem.Allocator, seed: u64, chaos_enabled: bool) !Universe {
    var clock = Clock.init();
    var rng = DeterministicRNG.init(seed);
    var bank = Bank.init(allocator, &clock);
    defer bank.deinit();
    bank.chaos_enabled = chaos_enabled;

    var scheduler = Scheduler.init(allocator, &clock, &rng);
    defer scheduler.deinit();

    var i: u32 = 0;
    while (i < cfg.accounts_count) : (i += 1) {
        try bank.createAccount(i, cfg.balance_initial);
    }

    const expected_total = bank.initial_total_balance;

    var transfer_id: u64 = 0;
    while (transfer_id < cfg.universe_transfer_count) : (transfer_id += 1) {
        const from = rng.rng.random().uintLessThan(u32, cfg.accounts_count);
        var to = rng.rng.random().uintLessThan(u32, cfg.accounts_count);
        while (to == from) {
            to = rng.rng.random().uintLessThan(u32, cfg.accounts_count);
        }

        const amount = rng.rng.random().uintLessThan(u64, 1000) + 1;

        try scheduler.scheduleRand(
            transfer_id + 100_000,
            50_000,
            .{
                .transfer = .{
                    .from = from,
                    .to = to,
                    .amount = amount,
                },
            },
        );
    }

    var transfers_completed: u64 = 0;
    while (scheduler.next()) |event| {
        switch (event.event_type) {
            .transfer => {
                const payload = event.payload.transfer;
                const result = try bank.transfer(.{
                    .id = transfers_completed,
                    .from = payload.from,
                    .to = payload.to,
                    .amount = payload.amount,
                    .timestamp = clock.now(),
                });

                if (result == .SUCCESS) {
                    transfers_completed += 1;
                }
            },
            else => {},
        }
    }

    return .{
        .seed = seed,
        .success = true,
        .error_type = null,
        .transfers_completed = transfers_completed,
        .final_balance = bank.getTotalBalance(),
        .expected_balance = expected_total,
    };
}

const Universe = struct {
    seed: u64,
    success: bool,
    error_type: ?ErrorType,
    transfers_completed: u64,
    final_balance: i64,
    expected_balance: i64,
};

const ErrorType = enum {
    UNDEFINED,
    NEGATIVE_BALANCE,
    CONSTRAINT_VIOLATION,
    UNHANDLED_EXCEPTION,
};

const std = @import("std");

pub const DeterministicRNG = struct {
    seed: u64,
    rng: std.Random.Xoshiro256,

    pub fn init(seed: u64) DeterministicRNG {
        return .{
            .seed = seed,
            .rng = std.Random.Xoshiro256.init(seed),
        };
    }

    pub fn random(self: *DeterministicRNG) std.Random {
        return self.rng.random();
    }

    pub fn chance(self: *DeterministicRNG, probability: f64) bool {
        const roll = self.rng.random().float(f64);

        return roll < probability;
    }

    pub fn oneOf(self: *DeterministicRNG, comptime T: type, items: []const T) T {
        const idx = self.rng.random().uintLessThan(usize, items.len);

        return items[idx];
    }

    pub fn delay(self: *DeterministicRNG, min: u64, max: u64) u64 {
        return self.rng.random().intRangeAtMost(u64, min, max);
    }

    pub fn getSeed(self: *const DeterministicRNG) u64 {
        return self.seed;
    }
};

test "rng state is deterministic from seed" {
    var rng_a = DeterministicRNG.init(131);
    var rng_b = DeterministicRNG.init(131);

    var i: usize = 0;
    while (i < 1_000) : (i += 1) {
        const a = rng_a.rng.random().int(u64);
        const b = rng_b.rng.random().int(u64);

        try std.testing.expectEqual(a, b);
    }
}

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
        return self.rng.ranodm().intRangeAtMost(u64, min, max);
    }

    pub fn getSeed(self: *const DeterministicRNG) u64 {
        return self.seed;
    }
};

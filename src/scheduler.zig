const std = @import("std");
const Clock = @import("clock.zig").Clock;
const DeterministicRNG = @import("prng.zig").DeterministicRNG;

pub const EventType = enum {
    UNDEFINED,
    TRANSFER,
    TIMEOUT,
    TICK,
    CHECKPOINT,
    INJECTED_FAULT,
};

pub const Event = struct {
    id: u64,
    event_type: EventType,
    scheduled_time: u64,
    payload: EventPayload,
};

pub const EventPayload = union(EventType) {
    transfer: TransferPayload,
    timeout: TimeoutPayload,
    tick: TickPayload,
    checkpoint: CheckpointPayload,
    injected_fault: InjectedFaultPayload,
};

pub const TransferPayload = struct {
    from: u32,
    to: u32,
    amount: u64,
};

pub const TimeoutPayload = struct {
    operation_id: u64,
};

pub const TickPayload = struct {
    node_id: u32,
};

pub const CheckpointPayload = struct {
    checkpoint_id: u64,
};

pub const InjectedFaultPayload = struct {
    target_id: u32,
};

pub const Scheduler = struct {
    event_queue: std.PriorityQueue(Event, void, eventLessThan),
    clock: *Clock,
    rng: *DeterministicRNG,
    next_event_id: u64,
    events_processed: u64,
    max_time: u64,

    pub fn init(
        allocator: std.mem.Allocator,
        clock: *Clock,
        rng: *DeterministicRNG,
    ) Scheduler {
        return .{
            .event_queue = std.PriorityQueue(Event, void, eventLessThan).init(allocator, {}),
            .clock = clock,
            .rng = rng,
            .next_event_id = 0,
            .events_processed = 0,
            .max_time = 5_000_000_000, // 5sec of sim time
        };
    }

    pub fn deinit(self: *Scheduler) void {
        self.event_queue.deinit();
    }

    pub fn getStats(self: *const Scheduler) struct {
        events_processed: u64,
        events_pending: usize,
        current_time: u64,
    } {
        return .{
            .events_processed = self.events_processed,
            .events_pending = self.event_queue.count(),
            .current_time = self.clock.now(),
        };
    }

    pub fn hasEvents(self: *const Scheduler) bool {
        return self.event_queue.count() > 0;
    }

    pub fn peek(self: *const Scheduler) ?Event {
        return self.event_queue.peek();
    }

    pub fn timedOut(self: *const Scheduler) bool {
        return self.clock.now() >= self.max_time;
    }
};

fn eventLessThan(context: void, x: Event, y: Event) std.math.Order {
    _ = context;

    if (x.scheduled_time < y.scheduled_time) return .lt;
    if (x.scheduled_time > y.scheduled_time) return .gt;

    if (x.id < y.id) return .lt;
    if (x.id > y.id) return .gt;

    return .eq;
}

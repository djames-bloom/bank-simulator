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
    ScheduledTime: u64,
    Payload: EventPayload,
};

pub const EventPayload = union(EventType) {
    transfer: TransferPayload,
    timeout: TimeoutPayload,
    tick: TickPayload,
    checkpoint: CheckpointPayload,
    injectedFault: InjectedFaultPayload,
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

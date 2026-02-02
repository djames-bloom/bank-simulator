const std = @import("std");

pub const TransferState = enum {
    UNDEFINED,
    SUCCESS,
    INSUFFICIENT_BALANCE,
    ACCOUNT_NOT_FOUND,
    INJECTED_FAULT,
    INVARIANT_VIOLATION,
};

pub const AccountID = u32;

pub const Account = struct {
    id: AccountID,
    balance: i64,
    pending_operations: u32,
    version: u64,
};

pub const TransferReq = struct {
    id: u64,
    from: AccountID,
    to: AccountID,
    amount: u64,
    timestamp: u64,
};

pub const Bank = struct {
    accounts: std.AutoHashMap(AccountID, Account),
    transfer_log: std.ArrayList(TransferReq),
    total_transfers: u64,
    failed_transfers: u64,
    injected_faults: u64,
    initial_total_balance: i64,
    chaos_enabled: bool,

    pub fn init(
        allocator: std.mem.Allocator,
    ) Bank {
        return .{
            .accounts = std.AutoHashMap(AccountID, Account).init(allocator),
            .transfer_log = std.ArrayList(TransferReq).init(allocator),
            .total_transfers = 0,
            .failed_transfers = 0,
            .injected_faults = 0,
            .initial_total_balance = 0,
            .chaos_enabled = true, // def to on
        };
    }

    pub fn deinit(self: *Bank) void {
        self.accounts.deinit();
        self.transfer_log.deinit();
    }
};

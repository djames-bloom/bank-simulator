const std = @import("std");
const Clock = @import("clock.zig").Clock;

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
    clock: *Clock,

    pub fn init(
        allocator: std.mem.Allocator,
        clock: *Clock,
    ) Bank {
        return .{
            .accounts = std.AutoHashMap(AccountID, Account).init(allocator),
            .transfer_log = std.ArrayList(TransferReq).init(allocator),
            .total_transfers = 0,
            .failed_transfers = 0,
            .injected_faults = 0,
            .initial_total_balance = 0,
            .chaos_enabled = true, // def to on
            .clock = clock,
        };
    }

    pub fn deinit(self: *Bank) void {
        self.accounts.deinit();
        self.transfer_log.deinit();
    }

    pub fn createAccount(self: *Bank, id: AccountID, initial_balance: u64) !void {
        try self.accounts.put(id, .{
            .id = id,
            .balance = @intCast(initial_balance),
            .pending_operations = 0,
            .version = 0,
        });

        self.initial_total_balance += @intCast(initial_balance);
    }

    pub fn getAccount(self: *const Bank, id: AccountID) ?Account {
        return self.accounts.get(id);
    }

    pub fn getTotalBalance(self: *const Bank) i64 {
        var total: i64 = 0;
        var itt = self.accounts.valueIterator();

        while (itt.next()) |account| {
            total += account.balance;
        }

        return total;
    }

    pub fn getStats(self: *const Bank) struct {
        total: u64,
        failed: u64,
        faults: u64,
    } {
        return .{
            .total = self.total_transfers,
            .failed = self.failed_transfers,
            .faults = self.injected_faults,
        };
    }
};

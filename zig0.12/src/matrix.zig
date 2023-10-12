pub const std = @import("std");

pub const F16X64 = @Vector(64, f16); 

pub const block = struct {
    pub fn inverse(self: F16X64) F16X64 {
        var rst : F16X64 = undefined; 
        inline for (0..64) |i| {
            const ri = i / 8;
            const ci = i % 8; 
            const vi = ci * 8 + ri; 
            rst[vi] = self[i]; 
        }
        return rst; 
    }
};

pub const Matrix = struct {
    content: [*] align(128) F16X64, 
    col: usize, 
    size: usize, 
    allocator: std.mem.Allocator, 
    pub fn init(row: usize, col: usize, allocator: std.mem.Allocator) !Matrix {
        std.debug.assert(row != 0);
        std.debug.assert(col != 0);
        const size = @mulWithOverflow(row, col);
        std.debug.assert(size.@"1" == 0);
        var self: Matrix = undefined; 
        self.col = col; 
        self.size = size.@"0";
        self.allocator = allocator; 
        const p = try allocator.alignedAlloc(F16X64, 128, size.@"0"); 
        self.content = p.ptr; 
        return self;  
    }
    pub fn deinit(self: Matrix) void {
        self.allocator.free(self.content[0..self.size]);  
    }
    pub fn clear(self: Matrix, row: usize, col: usize) void {
        const size = @mulWithOverflow(row, self.col); 
        std.debug.assert(size.@"1" == 0);
        const idx = @addWithOverflow(size.@"0", col); 
        std.debug.assert(idx.@"1" == 0);
        const content = &self.content[idx.@"0"];
        content.*.content = 0;
    }
};

pub const WrapMatrix = struct {
    block_impl : Matrix, 
    col: usize, 
    size: usize, 
    pub fn init(row: usize, col: usize, allocator: std.mem.Allocator) !WrapMatrix {
        std.debug.assert(row <= std.math.maxInt(usize) - 7); 
        const implRow = (row + 7) / 8; 
        std.debug.assert(col <= std.math.maxInt(usize) - 7); 
        const implCol = (col + 7) / 8; 
        var self: WrapMatrix = undefined; 
        self.block_impl = try Matrix.init(implRow, implCol, allocator);
        self.col = col; 
        const size = @mulWithOverflow(row, col);
        std.debug.assert(size.@"1" == 0);
        self.size = size.@"0";
        return self;  
    } 
    pub fn clear(self: WrapMatrix) void {
        for (self.block_impl.content[0..self.block_impl.size]) |*b| {
            b.* = @splat(0);
        }
    }
    pub fn deinit(self: WrapMatrix) void {
        self.block_impl.deinit();
    } 
    pub fn at(self: WrapMatrix, row: usize, col: usize) *f16 {
        const self_row = @divExact(self.size, self.col); 
        std.debug.assert (row < self_row);
        std.debug.assert (col < self.col); 
        const block_row = row / 8; 
        const block_col = col / 8;
        const block_idx = block_row * self.block_impl.col + block_col;
        const ref = &self.block_impl.content[block_idx][(row % 8) * 8 + (col % 8)];
        return ref;   
    }
    pub inline fn getRow(self: WrapMatrix) usize {
        return @divExact(self.size, self.col); 
    }
};

pub fn foreach(wrap: WrapMatrix, fun: *const fn (f16) void, line_separate: ?*const fn () void, col_separate: ?*const fn () void ) void {
    const row = @divExact(wrap.size, wrap.col); 
    for (0..row) |r| {
        for (0..wrap.col) |c| {
            fun(wrap.at(r, c).*); 
            if (c == wrap.col - 1) {
                if (line_separate) |lc| {
                    lc(); 
                }
            } else {
                if (col_separate) |cc| {
                    cc(); 
                }
            }
        }
    }
}

pub fn save(wrap: WrapMatrix, file: std.fs.File) !void {
    const writer = file.writer(); 
    try writer.writeIntLittle(usize, wrap.col); 
    try writer.writeIntLittle(usize, wrap.size); 
    const content = wrap.block_impl.content[0..wrap.block_impl.size]; 
    for (content) |c| {
        const ptr: [*]const u8 = @ptrCast(&c); 
        try writer.writeAll(ptr[0..128]);
    }
}

pub fn load(allocator: std.mem.Allocator, file: std.fs.File) !WrapMatrix {
    var col: usize = undefined; 
    var size: usize = undefined; 
    const reader = file.reader(); 
    col = try reader.readIntLittle(usize); 
    size = try reader.readIntLittle(usize); 
    const row = @divExact(size, col); 
    var wrap: WrapMatrix = try WrapMatrix.init(row, col, allocator);
    errdefer wrap.deinit();  
    for (wrap.block_impl.content[0..wrap.block_impl.size]) |*c| {
        const ptr: [*]u8 = @ptrCast(c); 
        const len = try reader.readAll(ptr[0..128]);
        std.debug.assert(len == 128); 
    } 
    return wrap; 
}

pub fn debug(out: std.fs.File, matrix: WrapMatrix) !void {
    const writer = out.writer();
    const col = matrix.col; 
    const row = matrix.getRow(); 
    for (0..row) |r| {
        for (0..col) |c| {
            try writer.print("{d:.1}{s}", .{ matrix.at(r, c).*, if (c == col - 1) "\n" else " "}); 
        }
    }
}

test {
    var wr: WrapMatrix = try WrapMatrix.init(10, 10, std.testing.allocator); 
    wr.clear(); 
    try save(wr, std.io.getStdOut());
}

pub const multiplication = @import("multiplication.zig");
pub const addition = @import("addition.zig");
pub const unitary = @import("unitary.zig");
pub const csv = @import("csv.zig"); 
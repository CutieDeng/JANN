pub const block = @import("../block/block.zig");
pub const F16X64 = block.F16X64; 

pub const unitary = @import("unitary.zig");
pub const binary = @import("binary.zig"); 

pub const serialize = @import("serialize.zig");

const std = @import("std"); 
const assert = std.debug.assert; 

pub const Matrix = struct {
    data: block.Matrix, 
    col: usize, 
    size: usize, 
    pub fn init(row: usize, col: usize, allocator: std.mem.Allocator) !Matrix {
        const block_row = row / 8 + if (row % 8 == 0) @as(usize, 0) else @as(usize, 1);
        const block_col = col / 8 + if (col % 8 == 0) @as(usize, 0) else @as(usize, 1); 
        const size = row * col; 
        const self: Matrix = .{
            .data = try block.Matrix.init(block_row, block_col, allocator), 
            .col = col, 
            .size = size, 
        };
        return self; 
    }
    pub fn deinit(self: Matrix) void {
        self.data.deinit(); 
    }
    pub fn getRow(self: Matrix) usize {
        return @divExact(self.size, self.col);
    }
    pub inline fn at(self: Matrix, row: usize, col: usize) *f16 {
        assert (col < self.col); 
        assert (row < self.getRow()); 
        return unsafe_at(self, row, col); 
    }
    pub fn unsafe_at(self: Matrix, row: usize, col: usize) *f16 {
        const row_block = row / 8; 
        const row_offset = row % 8; 
        const col_block = col / 8; 
        const col_offset = col % 8; 
        const this_block = self.data.at(row_block, col_block); 
        return &this_block[row_offset * 8 + col_offset]; 
    } 
};

comptime {
    _ = unitary;
    _ = binary;
}
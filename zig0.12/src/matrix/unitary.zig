const matrix = @import("matrix.zig");
const F16X64 = matrix.F16X64; 

const std = @import("std"); 
const assert = std.debug.assert; 

pub const Idx = struct { row: usize, col: usize }; 

pub fn fill(self: matrix.Matrix, other: f16) void {
    const splat : matrix.F16X64 = @splat(other); 
    for (self.data.data[0..self.data.size]) |*b| {
        b.* = splat; 
    } 
    clear_up(self); 
}

pub fn multiply_scalar(self: matrix.Matrix, other: f16) void {
    const splat : matrix.F16X64 = @splat(other); 
    for (self.data.data[0..self.data.size]) |*b| {
        b.* *= splat; 
    }
}

pub inline fn divide_scalar(self: matrix.Matrix, other: f16) void {
    const divisor = 1 / other; 
    return multiply_scalar(self, divisor); 
}

pub fn duplicate(self: matrix.Matrix) !matrix.Matrix {
    const other = try matrix.Matrix.init(self.getRow(), self.col, self.data.allocator); 
    for (self.data.data[0..self.data.size], other.data.data[0..other.data.size]) |a, *b| {
        b.* = a; 
    } 
    return other; 
}

pub fn add_scalar(self: matrix.Matrix, other: f16) void { 
    const splat : F16X64 = @splat(other); 
    for (self.data.data[0..self.data.size]) |*b| {
        b.* += splat; 
    } 
    clear_up(self); 
}

pub fn minus_scalar(self: matrix.Matrix, other: f16) void { 
    const m = -other; 
    return add_scalar(self, m); 
} 

pub fn apply(self: matrix.Matrix, other: anytype) void {
    for (self.data.data[0..self.data.size], 0..) |*b, idx| {
        const row_idx = idx / self.data.col; 
        const col_idx = idx % self.data.col; 
        inline for (0..64) |i| {
            const ri = i / 8; 
            const ci = i % 8; 
            b[i] = other(row_idx * 8 + ri, col_idx * 8 + ci, b[i]);
        }
    } 
    clear_up(self); 
}

pub fn reduce_row(rst: matrix.Matrix, self: matrix.Matrix) void {
    assert (rst.col == self.col); 
    assert (rst.getRow() == 1); 
    fill(rst, 0); 
    const rst_idx : Idx = .{ .row = self.data.getRow(), .col = self.data.col }; 
    for (0..rst_idx.col) |rcol| {
        for (0..rst_idx.row) |rrow| {
            rst.data.data[rcol] += self.data.data[rrow * rst_idx.col + rcol]; 
        }
    }
    inline for (1..8) |ridx| {
        inline for (0..8) |cidx| {
            const idx = ridx * 8 + cidx; 
            rst.data.data[0][cidx] += rst.data.data[0][idx]; 
        }
    }
}

pub fn clear_up(self: matrix.Matrix) void {
    const row = self.getRow(); 
    const col = self.col;
    {
        const delta = 8 - row % 8; 
        if (delta != 8) {
            for (0..col) |c| {
                for (0..delta) |ridx| {
                    self.unsafe_at(row + ridx, c).* = 0; 
                }
            }
        }
    }
    {
        const delta = 8 - col % 8; 
        if (delta != 8) { 
            for (0..row) |ri| {
                for (0..delta) |c| {
                    self.unsafe_at(ri, col + c).* = 0; 
                }
            }
        } 
    }
}

pub fn reduce_col(rst: matrix.Matrix, self: matrix.Matrix) void { 
    assert (rst.getRow() == self.getRow());
    assert (rst.col == 1); 
    fill(rst, 0); 
    const rst_idx : Idx = .{ .row = self.data.getRow(), .col = self.data.col }; 
    for (0..rst_idx.row) |rcol| {
        for (0..rst_idx.col) |rrow| {
            rst.data.data[rcol] += self.data.data[rrow * rst_idx.col + rcol]; 
        }
    } 
    inline for (0..8) |ridx| {
        const didx = ridx * 8; 
        inline for (1..8) |cidx| {
            const idx = ridx * 8 + cidx; 
            rst.data.data[0][didx] += rst.data.data[0][idx]; 
        }
    } 
}

pub fn transpose(self: matrix.Matrix) !matrix.Matrix {
    const other = try matrix.Matrix.init(self.col, self.getRow(), self.data.allocator); 
    var result_idx: Idx = .{
        .row = 0, 
        .col = 0, 
    }; 
    const bound: Idx = .{
        .row = other.data.getRow(), 
        .col = other.data.col, 
    }; 
    while (result_idx.row < bound.row) {
        const output_block_idx = result_idx.col + result_idx.row * bound.col; 
        const input_block_idx = result_idx.row + result_idx.col * bound.row; 
        other.data.data[output_block_idx] = block_transpose(self.data.data[input_block_idx]);
        if (result_idx.col == bound.col - 1) {
            result_idx.col = 0; 
            result_idx.row += 1; 
        } else {
            result_idx.col += 1;  
        }
    }
    return other; 
} 

pub fn block_transpose(self: F16X64) F16X64 {
    var rst : F16X64 = undefined; 
    inline for (0..64) |i| {
        const ri = i / 8;
        const ci = i % 8; 
        const vi = ci * 8 + ri; 
        rst[vi] = self[i]; 
    }
    return rst; 
}

test {
    var two = try matrix.Matrix.init(1, 2, std.testing.allocator);
    defer two.deinit(); 
    clear_up(two); 
    two.at(0, 0).* = 1; 
    two.at(0, 1).* = 2; 
    multiply_scalar(two, 2); 
    assert(two.at(0, 0).* == 2); 
    assert(two.at(0, 1).* == 4); 
}

test {
    const one = try matrix.Matrix.init(1, 1, std.testing.allocator); 
    defer one.deinit(); 
    clear_up(one); 
    one.at(0, 0).* = 5; 
    const two = try duplicate(one);
    defer two.deinit(); 
    assert(two.at(0, 0).* == 5); 
    assert(two.getRow() == 1); 
    assert(two.col == 1); 
    one.at(0, 0).* = 0; 
    assert(two.at(0, 0).* == 5); 
    assert(one.at(0, 0).* == 0); 
}

test {
    const v = try matrix.Matrix.init(2, 1, std.testing.allocator);
    defer v.deinit(); 
    clear_up(v);
    v.at(0, 0).* = 1; 
    v.at(1, 0).* = 2; 
    const vt = try transpose(v); 
    defer vt.deinit(); 
    assert(vt.at(0, 0).* == 1); 
    assert(vt.at(0, 1).* == 2);  
}

test {
    const m = try matrix.Matrix.init(9, 1, std.testing.allocator);
    defer m.deinit(); 
    fill(m, 1); 
    const m2 = try transpose(m); 
    defer m2.deinit(); 
    assert(m2.at(0, 0).* == 1);
    assert(m2.at(0, 8).* == 1);
    assert(m2.at(0, 2).* == 1);
}

test {
    const zero = try matrix.Matrix.init(1, 1, std.testing.allocator); 
    defer zero.deinit();
    clear_up(zero); 
    zero.at(0, 0).* = 0; 
    add_scalar(zero, 5); 
    assert(zero.at(0, 0).* == 5); 
}

test { 
    const zero = try matrix.Matrix.init(2, 2, std.testing.allocator);
    defer zero.deinit(); 
    fill(zero, 0); 
    assert(zero.at(0, 0).* == 0); 
    const C = struct {
        inline fn set(row: usize, col: usize, _: f16) f16 {
            _ = col;
            _ = row;
            return 1; 
        } 
    };
    apply(zero, C.set); 
    assert(zero.at(0, 0).* == 1); 
    assert(zero.at(0, 1).* == 1); 
    assert(zero.at(1, 0).* == 1); 
    assert(zero.at(1, 1).* == 1); 
}

test {
    const zero = try matrix.Matrix.init(2, 2, std.testing.allocator); 
    defer zero.deinit(); 
    fill(zero, 1);
    const row = try matrix.Matrix.init(1, 2, std.testing.allocator); 
    defer row.deinit(); 
    reduce_row(row, zero); 
    assert(row.at(0, 0).* == 2); 
    assert(row.at(0, 1).* == 2); 
    assert(row.col == 2);
    assert(row.getRow() == 1);
}

test {
    const zero = try matrix.Matrix.init(2, 2, std.testing.allocator); 
    defer zero.deinit(); 
    fill(zero, 2);
    const col = try matrix.Matrix.init(2, 1, std.testing.allocator); 
    defer col.deinit(); 
    reduce_col(col, zero); 
    assert(col.at(0, 0).* == 4); 
    assert(col.at(1, 0).* == 4); 
    assert(col.col == 1);
    assert(col.getRow() == 2); 
}
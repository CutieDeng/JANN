pub const matrix = @import("matrix.zig");

pub const schur_product = hadamard_product; 

const std = @import("std"); 
const assert = std.debug.assert; 

pub fn hadamard_product(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert (rst.col == lhs.col); 
    assert (rst.col == rhs.col); 
    const size = rst.size; 
    assert (size == lhs.size); 
    assert (size == rhs.size); 
    for (rst.content[0..size], lhs.content[0..size], rhs.content[0..size]) |*a, l, r| {
        a.* = l * r; 
    }
    return ; 
}

pub fn multiply(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    const rst_row = @divExact(rst.size, rst.col);
    const lhs_row = @divExact(lhs.size, lhs.col); 
    assert (rst_row == lhs_row); 
    assert (rst.col == rhs.col); 
    for (0..rst.size) |ridx| {
        const rrow = ridx / rst.col; 
        const rcol = ridx % rst.col;
        var tmp: matrix.F16X64 = @splat(0);    
        for (0..lhs.col) |idx| {
            const a = @"multiply a block"(lhs.content[rrow * lhs.col + idx], rhs.content[idx * rhs.col + rcol]); 
            tmp += a; 
        }
        rst.content[ridx] = tmp; 
    }
    return ; 
}

pub fn @"multiply a block"(lhs: matrix.F16X64, rhs: matrix.F16X64) matrix.F16X64 {
    @setFloatMode(std.builtin.FloatMode.Optimized); 
    var rst: matrix.F16X64 = undefined; 
    inline for (0..64) |ridx| {
        var v: f64 = 0; 
        const rrow = ridx / 8; 
        const rcol = ridx % 8; 
        inline for (0..8) |s| {
            v += lhs[rrow * 8 + s] * rhs[s * 8 + rcol]; 
        }
        rst[ridx] = @floatCast(v); 
    }
    return rst; 
}
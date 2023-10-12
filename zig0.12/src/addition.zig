const matrix = @import("matrix.zig");

const std = @import("std"); 
const assert = std.debug.assert; 

pub fn plus(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert (rst.col == lhs.col); 
    assert (rst.col == rhs.col);
    const size = rst.size;
    assert (size == lhs.size); 
    assert (size == rhs.size); 
    for (rst.content[0..size], lhs.content[0..size], rhs.content[0..size]) |*a, l, r| {
        a.* = l + r; 
    }
    return ; 
}
pub const matrix = @import("matrix.zig"); 

const std = @import("std"); 
const assert = std.debug.assert; 

pub fn reverse(rst: matrix.Matrix, src: matrix.Matrix) void {
    const src_col = src.col;
    const src_row = @divExact(src.size, src_col);  
    assert (rst.col == src_row); 
    assert (rst.size == src.size); 
    for (0..src_row) |r| {
        for (0..src_col) |c| {
            const src_idx = r * src_col + c; 
            const rst_idx = c * src_row + r; 
            rst[rst_idx] = matrix.block.inverse(src[src_idx]);
        }
    }
}

pub fn clone(src: matrix.Matrix) !matrix.Matrix {
    var rst: matrix.Matrix = try matrix.Matrix.init(@divExact(src.size, src.col), src.col, src.allocator);
    @memcpy(rst.content[0..rst.size], src.content[0..src.size]);
    return rst; 
}
const matrix = @import("matrix.zig"); 
const unitary = @import("unitary.zig"); 

const std = @import("std"); 
const assert = std.debug.assert; 

pub fn add(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert_matrix_size_match(rst, lhs); 
    assert_matrix_size_match(rst, rhs); 
    const size = rst.data.size;
    for (rst.data.data[0..size], lhs.data.data[0..size], rhs.data.data[0..size]) |*a, l, r| {
        a.* = l + r; 
    }
}

test {
    var a = try matrix.Matrix.init(3, 3, std.testing.allocator);
    defer a.deinit(); 
    unitary.fill(a, 2); 
    var b = try unitary.duplicate(a);
    defer b.deinit();  
    var c = try unitary.duplicate(a);
    defer c.deinit();  
    add(c, a, b); 
    assert (c.at(0, 0).* == 4);
    assert (c.at(1, 0).* == 4);
    assert (c.at(2, 0).* == 4);
    assert (c.at(0, 1).* == 4);
}

pub fn assert_matrix_size_match(lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert (lhs.col == rhs.col); 
    assert (lhs.size == rhs.size); 
} 

pub fn minus(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert_matrix_size_match(rst, lhs); 
    assert_matrix_size_match(rst, rhs); 
    const size = rst.data.size;
    for (rst.data.data[0..size], lhs.data.data[0..size], rhs.data.data[0..size]) |*a, l, r| {
        a.* = l - r; 
    }
}

test {
    var a = try matrix.Matrix.init(3, 3, std.testing.allocator);
    defer a.deinit(); 
    unitary.fill(a, 2); 
    var b = try unitary.duplicate(a);
    defer b.deinit();  
    var c = try unitary.duplicate(a);
    defer c.deinit();  
    minus(c, a, b); 
    assert (c.at(0, 0).* == 0);
    assert (c.at(1, 0).* == 0);
    assert (c.at(2, 0).* == 0);
    assert (c.at(0, 1).* == 0);
}

pub fn hadamard_product(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert_matrix_size_match(rst, lhs); 
    assert_matrix_size_match(rst, rhs); 
    const size = rst.data.size; 
    for (rst.data.data[0..size], lhs.data.data[0..size], rhs.data.data[0..size]) |*a, l, r| {
        a.* = l * r; 
    } 
}

test {
    var a = try matrix.Matrix.init(2, 3, std.testing.allocator);
    defer a.deinit(); 
    unitary.fill(a, 3); 
    var b = try unitary.duplicate(a);
    defer b.deinit();  
    var c = try unitary.duplicate(a);
    defer c.deinit();  
    hadamard_product(c, a, b); 
    assert (c.at(0, 0).* == 9);
    assert (c.at(1, 0).* == 9);
    assert (c.at(0, 1).* == 9);
    assert (c.at(0, 2).* == 9);
}

pub fn multiply(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    {
        assert (rst.col == rhs.col); 
        const row = rst.getRow(); 
        assert (row == lhs.getRow()); 
        const middle = lhs.col;
        assert (middle == rhs.getRow()); 
        unitary.fill(rst, 0); 
    }
    const row = rst.data.getRow(); 
    const col = rst.data.col;  
    const mid = lhs.data.col;  
    for (0..row) |r| {
        for (0..col) |c| {
            for (0..mid) |m| {
                rst.data.at(r, c).* += multiply_block(lhs.data.at(r, m).*, rhs.data.at(m, c).*);
            }
        }
    } 
}

pub fn multiply_block(lhs: matrix.F16X64, rhs: matrix.F16X64) matrix.F16X64 {
    var rst : matrix.F16X64 = @splat(0);
    inline for (0..8) |r| {
        inline for (0..8) |c| {
            const idx = r * 8 + c; 
            inline for (0..8) |m| {
                rst[idx] += lhs[r * 8 + m] * rhs[m * 8 + c];  
            }
        }
    }
    return rst; 
}

test {
    const row = try matrix.Matrix.init(1, 3, std.testing.allocator); 
    defer row.deinit(); 
    unitary.fill(row, 2); 
    const col = try matrix.Matrix.init(3, 1, std.testing.allocator); 
    defer col.deinit(); 
    unitary.fill(col, 3); 
    var rst = try matrix.Matrix.init(1, 1, std.testing.allocator); 
    defer rst.deinit(); 
    multiply(rst, row, col); 
    assert (rst.at(0, 0).* == 18); 
}

pub fn hadamard_divide(rst: matrix.Matrix, lhs: matrix.Matrix, rhs: matrix.Matrix) void {
    assert_matrix_size_match(rst, lhs); 
    assert_matrix_size_match(rst, rhs); 
    const size = rst.data.size; 
    for (rst.data.data[0..size], lhs.data.data[0..size], rhs.data.data[0..size]) |*a, l, r| {
        a.* = l / r; 
    } 
    unitary.clear_up(rst); 
}
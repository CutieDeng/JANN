pub const std = @import("std");

pub const DataType = f64; 

/// Matrix struct 
/// 
/// # States 
/// 
/// * Uninitialzed, when you declare a matrix, it is uninitialzed. 
/// * Initialized, when you call `init` function or other functions with `as_init` suffix, it will be initialized. 
/// * Deinitialized, when you call `deinit` function, it will be deinitialized. 
/// 
/// # Error 
/// 
/// * MatrixSizeMismatch, when you call the operations fucntions on different matrixes, it would check the prerequest and return this error when the size is not matched. 
/// * NotRowVector, when you call the extension functions on a matrix which is not a row vector, it would check the prerequest and return this error when the matrix is not a row vector. 
/// * NotColVector, when you call the extension functions on a matrix which is not a col vector, it would check the prerequest and return this error when the matrix is not a col vector. 
/// 
/// * std.mem.Allocator.Error, when you call the `init` function, it would allocate memory for the matrix, and it would return the error when the allocator failed to allocate memory.  
/// 
/// # Fields 
/// 
/// * `data` - The data of the matrix. 
/// * `row` - The row of the matrix.         
/// * `col` - The col of the matrix. 
/// * `allocator` - The allocator of the matrix. 
/// 
/// # Examples 
/// 
/// ``` 
/// const std = @import("std"); 
/// const Matrix = @import("matrix.zig").Matrix; 
/// ``` 
/// 
/// # Basic functions 
/// 
/// * `size` - Get the size of the matrix. 
/// * `init` - Initialize the matrix. 
/// * `deinit` - Deinitialize the matrix. 
/// * `get` - Get the value of the matrix, unsafe operator without bound check. 
/// * `set` - Set the value of the matrix, unsafe operator without bound check. 
/// 
/// # Operations 
/// 
pub const Matrix = struct {

    pub const MatrixError = error{
        MatrixSizeMismatch,
        NotRowVector, 
        NotColVector, 
    } 
    || std.mem.Allocator.Error; 
    data: [*]DataType,
    row: usize,
    col: usize,
    allocator: std.mem.Allocator,
    pub fn size(self: *const Matrix) usize {
        return self.row * self.col;
    } 
    pub fn const_slice(self: *const Matrix) [] const DataType {
        return self.data[0..self.size()];
    } 
    pub fn mut_slice(self: *Matrix) [] DataType {
        return self.data[0..self.size()];
    } 
    pub fn init(matrix: *Matrix, row: usize, col: usize, allocator: std.mem.Allocator) MatrixError!void {
        const data = try allocator.alloc(DataType, row * col); 
        std.debug.assert( data.len == row * col ); 
        const data_ptr = data.ptr; 
        matrix.* = Matrix{
            .data = data_ptr, 
            .row = row,
            .col = col,
            .allocator = allocator,
        };
    }
    pub fn deinit(matrix: *Matrix) void {
        matrix.allocator.free(
            matrix.mut_slice() 
        ); 
    }
    fn assert_index(matrix: *const Matrix, row: usize, col: usize) void {
        std.debug.assert(row < matrix.row);
        std.debug.assert(col < matrix.col);
    } 
    pub fn get(matrix: *const Matrix, row: usize, col: usize) callconv(.Inline) DataType {
        assert_index(matrix, row, col); 
        return matrix.data[row * matrix.col + col];
    } 
    pub fn set(matrix: *Matrix, row: usize, col: usize, value: DataType) callconv(.Inline) void {
        assert_index(matrix, row, col); 
        matrix.data[row * matrix.col + col] = value;
    }

    pub fn add_assign(matrix: *Matrix, other: *const Matrix) MatrixError!void {
        if (matrix.row != other.row or matrix.col != other.col) {
            return error.MatrixSizeMismatch;
        }
        for (matrix.mut_slice(), other.const_slice()) |*value, other_value| {
            value.* += other_value;
        } 
    } 

    pub fn minus_assign(matrix: *Matrix, other: *const Matrix) MatrixError!void {
        if (matrix.row != other.row or matrix.col != other.col) {
            return error.MatrixSizeMismatch;
        }
        for (matrix.mut_slice(), other.const_slice()) |*value, other_value| {
            value.* -= other_value;
        } 
    } 
    pub fn multiply_as_init(result: *Matrix, left: *const Matrix, right: *const Matrix, allocator: std.mem.Allocator) MatrixError!void {
        if (left.col != right.row) {
            return error.MatrixSizeMismatch;
        }
        try result.init(left.row, right.col, allocator); 
        errdefer result.deinit(); 
        multiply_assign(result, left, right) catch unreachable; 
    } 
    pub fn dot_product_assign(matrix: *Matrix, other: *const Matrix) MatrixError!void {
        if (matrix.row != other.row or matrix.col != other.col) {
            return error.MatrixSizeMismatch;
        }
        for (matrix.mut_slice(), other.const_slice()) |*value, other_value| {
            value.* *= other_value;
        } 
    } 
    pub fn clone_as_init(result: *Matrix, origin: *const Matrix, allocator: std.mem.Allocator) MatrixError!void {
        try result.init(origin.row, origin.col, allocator); 
        errdefer result.deinit(); 
        for (result.mut_slice(), origin.const_slice()) |*value, origin_value| {
            value.* = origin_value;
        } 
    } 
    pub fn multiply_assign(result: *Matrix, lhs: *const Matrix, rhs: *const Matrix) MatrixError!void {
        if (lhs.col != rhs.row) {
            return error.MatrixSizeMismatch;
        }
        if (result.row != lhs.row) {
            return error.MatrixSizeMismatch; 
        }
        if (result.col != rhs.col) {
            return error.MatrixSizeMismatch; 
        }
        // multiply 
        var i : usize = 0; 
        var j : usize = 0; 
        var k : usize = 0; 
        while (i < result.row) : (i += 1) {
            j = 0;
            while (j < result.col) : (j += 1) {
                k = 0;
                var tmp : DataType = 0; 
                while (k < lhs.col) : (k += 1) {
                    tmp += lhs.get(i, k) * rhs.get(k, j); 
                }
                result.set(i, j, tmp); 
            }
        } 
    } 
    pub fn transpose_as_init(result: *Matrix, origin: *const Matrix, allocator: std.mem.Allocator) MatrixError!void {
        try result.init(origin.col, origin.row, allocator); 
        errdefer result.deinit(); 
        transpose_assign(result, origin) catch unreachable; 
    } 
    pub fn transpose_assign(matrix: *Matrix, origin: *const Matrix) MatrixError!void {
        if (matrix.row != origin.col or matrix.col != origin.row) {
            return error.MatrixSizeMismatch;
        }
        for (matrix.mut_slice(), 0..) |*value, i| {
            value.* = origin.data[i % origin.row * origin.col + i / origin.row];
        } 
    }
    pub fn sum_to_col_vec_as_init(matrix: *Matrix, origin: *const Matrix, allocator: std.mem.Allocator) MatrixError!void {
        try matrix.init(origin.row, 1, allocator); 
        errdefer matrix.deinit(); 
        sum_to_col_vec(matrix, origin) catch unreachable; 
    } 
    pub fn sum_to_col_vec(matrix: *Matrix, origin: *const Matrix) MatrixError!void {
        if (matrix.row != origin.row or matrix.col != 1) {
            return error.MatrixSizeMismatch;
        } 
        var i: usize = 0; 
        while (i < origin.row) : (i += 1) {
            var j: usize = 0; 
            var tmp : DataType = 0; 
            while (j < origin.col) : (j += 1) {
                tmp += origin.get(i, j); 
            }
            tmp /= @intToFloat(DataType, origin.col); 
            matrix.set(i, 0, tmp); 
        } 
    }
    pub fn add_vec_assign(matrix: *Matrix, other: *const Matrix) MatrixError!void {
        if (matrix.row != other.row or other.col != 1) {
            return error.MatrixSizeMismatch;
        }
        var i: usize = 0; 
        while (i < matrix.row) : (i += 1) {
            var j : usize = 0; 
            while (j < matrix.col) : (j += 1) {
                matrix.set(i, j, matrix.get(i, j) + other.get(i, 0)); 
            } 
        }  
    }
    pub fn assign(matrix: *Matrix, other: *const Matrix) MatrixError!void {
        if (matrix.row != other.row or matrix.col != other.col) {
            return error.MatrixSizeMismatch;
        }
        for (matrix.mut_slice(), other.const_slice()) |*value, other_value| {
            value.* = other_value;
        } 
    } 
};

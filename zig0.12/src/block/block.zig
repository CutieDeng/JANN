pub const F16X64 = @Vector(64, f16); 

const std = @import("std"); 
const testing = std.testing; 
const assert = std.debug.assert; 

comptime {
    assert(@sizeOf(F16X64) == 128); 
}

pub const Matrix = struct {
    data: [*] align(128) F16X64, 
    col: usize, 
    size: usize, 
    allocator: std.mem.Allocator, 
    pub fn init(row: usize, col: usize, allocator: std.mem.Allocator) !Matrix {
        assert(row != 0);
        assert(col != 0);
        // ignore overflow, because it's the count of block 
        const size = row * col; 
        var self: Matrix = undefined; 
        self.col = col; 
        self.size = size; 
        self.allocator = allocator; 
        const p = try allocator.alignedAlloc(F16X64, 128, size); 
        self.data = p.ptr; 
        return self;  
    }
    pub fn deinit(self: Matrix) void {
        self.allocator.free(self.data[0..self.size]);  
    }
    pub fn getRow(self: Matrix) usize {
        return @divExact(self.size, self.col); 
    }
    pub fn at(self: Matrix, row: usize, col: usize) *F16X64 {
        assert (col < self.col); 
        const self_row = self.getRow(); 
        assert(row < self_row); 
        return &self.data[row * self.col + col]; 
    }
};

test "init" {
    var m = try Matrix.init(2, 3, testing.allocator); 
    defer m.deinit(); 
    assert (m.col == 3);
    assert (m.size == 6);
}
const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

pub const matrix = @import("matrix.zig"); 

pub fn debug_print(i: f16) void {
    std.debug.print("{d:.2}", .{i}); 
}
pub fn line() void {
    std.debug.print("\n", .{});  
}
pub fn block() void {
    std.debug.print(" ", .{}); 
}

test {
    var wrap : matrix.WrapMatrix = try matrix.WrapMatrix.init(2, 2, std.testing.allocator); 
    defer wrap.deinit(); 
    wrap.clear(); 
    wrap.at(0, 0).* = 15; 
    wrap.at(0, 1).* = 14; 
    wrap.at(1, 0).* = 13; 
    var wrap2 = try matrix.unitary.clone(wrap.block_impl); 
    var wrap3 = matrix.WrapMatrix {
        .block_impl = wrap2, 
        .col = wrap.col, 
        .size = wrap.size, 
    }; 
    defer wrap3.deinit(); 
    matrix.foreach(wrap, debug_print, line, block);
    matrix.foreach(wrap3, debug_print, line, block); 
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    const allocator = gpa.allocator(); 
    var wrap : matrix.WrapMatrix = try matrix.WrapMatrix.init(2, 2, allocator); 
    defer wrap.deinit(); 
    wrap.clear(); 
    wrap.at(0, 0).* = 15; 
    wrap.at(0, 1).* = 14; 
    wrap.at(1, 0).* = 13; 
    var wrap2 = try matrix.unitary.clone(wrap.block_impl); 
    var wrap3 = matrix.WrapMatrix {
        .block_impl = wrap2, 
        .col = wrap.col, 
        .size = wrap.size, 
    }; 
    defer wrap3.deinit(); 
    matrix.foreach(wrap, debug_print, line, block);
    matrix.foreach(wrap3, debug_print, line, block); 
    var wrap4 = try matrix.unitary.clone(wrap3.block_impl); 
    var wrap5 = matrix.WrapMatrix {
        .block_impl = wrap4, 
        .col = wrap.col, 
        .size = wrap.size, 
    };
    defer wrap5.deinit();  
    matrix.multiplication.multiply(wrap4, wrap.block_impl, wrap2); 
    matrix.foreach(wrap5, debug_print, line, block); 
}
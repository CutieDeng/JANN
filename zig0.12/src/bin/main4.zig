const std = @import("std"); 
const matrix = @import("matrix"); 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    if (false) {
        var m = try matrix.m2.Matrix.init(4, 4, allocator);
        defer m.deinit();  
        matrix.m2.unitary.fill(m, 2); 
        std.debug.print("size: {}\n", .{ m.size }); 
        const f = try std.fs.cwd().createFile("m.m2", .{}); 
        defer f.close(); 
        try matrix.m2.serialize.simple.store(f.writer(), m); 
    } else {
        const f = try std.fs.cwd().openFile("m.m2", .{});  
        var tmp = try matrix.m2.serialize.simple.load(f.reader(), allocator); 
        defer tmp.deinit(); 
        std.debug.print("size: {}\n", .{ tmp.size }); 
        for (0..tmp.size) |i| {
            const c = i % tmp.col; 
            const r = i / tmp.col; 
            std.debug.print("({},{}) = {d:}\n", .{ c, r, tmp.at(r, c).* }); 
        }
    }
}
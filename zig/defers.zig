pub fn main() !void {
    const std = @import("std"); 
    var i: i32 = 1; 
    while (i < 20) : (i += 1) {
        std.debug.print("i = {d}\n", .{i}) ; 
        defer {
            std.debug.print("defer: i = {d}\n", .{i}) ; 
        }
    }
}
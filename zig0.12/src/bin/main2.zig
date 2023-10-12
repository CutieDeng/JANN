pub const matrix = @import("matrix"); 
const std = @import("std"); 

pub fn main() !void {
    std.log.info("test", .{}); 
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator(); 
    const df = try std.fs.cwd().openFile("rst.bin", .{});
    const m = try matrix.load(allocator, df);
    try matrix.debug(std.io.getStdErr(), m); 
}
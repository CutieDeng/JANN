pub const matrix = @import("matrix");

const std = @import("std"); 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allo = gpa.allocator(); 
    const src = try std.fs.cwd().openFile("data/label.txt", .{}); 
    defer src.close(); 
    const src_x = try matrix.csv.read_from_csv(allo, src); 
    defer src_x.deinit(); 
    const out = try std.fs.cwd().createFile("label.txt", .{}); 
    defer out.close();  
    std.log.info("{}", .{ src_x }); 
    try matrix.debug(out, src_x);
}
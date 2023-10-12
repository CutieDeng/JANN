const std = @import("std");

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

const Allocator = std.mem.Allocator; 

fn read_data(allocator: Allocator, label: [] const u8, train: [] const u8, x_matrix: *matrix.WrapMatrix, y_matrix: *matrix.WrapMatrix) !void {
    var label_content: []u8 = undefined; 
    var label_split: std.ArrayList([]const u8) = undefined; 
    try read_one_file(allocator, label, &label_content, &label_split); 
    defer allocator.free(label_content); 
    defer label_split.deinit(); 
    var train_content: []u8 = undefined; 
    var train_split: std.ArrayList([]const u8) = undefined; 
    try read_one_file(allocator, train, &train_content, &train_split); 
    defer allocator.free(train_content); 
    defer train_split.deinit(); 
    try assign(x_matrix, allocator, 784, train_split.items); 
    errdefer x_matrix.deinit(); 
    try assign(y_matrix, allocator, 10, label_split.items);
    errdefer y_matrix.deinit(); 
    return ; 
}

fn assign(rst: *matrix.WrapMatrix, allocator: Allocator, col_suggest: usize, origin: []const []const u8, ) !void {
    var tmp = try matrix.WrapMatrix.init(origin.len, col_suggest, allocator);
    errdefer tmp.deinit();  
    for (0..origin.len) |lidx| {
        var cidx: usize = 0; 
        var sp = std.mem.splitScalar(u8, origin[lidx], ' ');
        while (true) {
            var s = sp.next() orelse break;  
            const val = std.fmt.parseFloat(f16, s) catch break;  
            tmp.at(lidx, cidx).* = val; 
            cidx += 1; 
        } 
    }
    rst.* = tmp; 
    return ; 
}

fn read_one_file(allocator: Allocator, file_name: [] const u8, content: *[] u8, split: *std.ArrayList([] const u8)) !void {
    const data = try std.fs.cwd().openDir("data", .{});
    const file = try data.openFile(file_name, .{}); 
    const slice = try file.readToEndAlloc(allocator, 100 << 20);
    errdefer allocator.free(slice);  
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit(); 
    var split_scalar = std.mem.splitScalar(u8, slice, '\n');
    while (true) {
        var nxt = split_scalar.next() orelse break; 
        const a = try list.addOne(); 
        a.* = nxt; 
    } 
    content.* = slice; 
    split.* = list; 
    return ; 
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allocator = gpa.allocator();
    var x: matrix.WrapMatrix = undefined; 
    var y: matrix.WrapMatrix = undefined; 
    try read_data(allocator, "label.txt", "train.txt", &x, &y);  
    defer x.deinit(); 
    defer y.deinit();  
}
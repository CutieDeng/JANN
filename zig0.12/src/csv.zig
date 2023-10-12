const std = @import("std"); 

const Allocator = std.mem.Allocator; 

const matrix = @import("matrix.zig"); 

pub fn read_from_csv(allocator: Allocator, file: std.fs.File) !matrix.WrapMatrix {
    const reader = file.reader(); 
    const content: [] const u8 = try reader.readAllAlloc(allocator, 100 << 20); 
    defer allocator.free(content); 
    var split = std.mem.splitScalar(u8, content, '\n'); 
    const List = std.ArrayList([]const u8); 
    var l : List = List.init(allocator);
    defer l.deinit(); 
    while (split.next()) |s| {
        if (s.len == 0)
            break; 
        ( try l.addOne() ).* = s; 
    }
    // check col size 
    if (l.items.len == 0) return error.InvalidCsv; 
    const head = l.items[0]; 
    var col_size: usize = 0;
    var sp = std.mem.splitScalar(u8, head, ' '); 
    while (sp.next()) |s| {
        if (s.len == 0)
            break; 
        col_size += 1; 
    } 
    var rst : matrix.WrapMatrix = try matrix.WrapMatrix.init(l.items.len, col_size, allocator); 
    errdefer rst.deinit(); 
    rst.clear(); 
    for (l.items, 0..) |li, ridx| {
        var li_sp = std.mem.splitScalar(u8, li, ' '); 
        var cidx: usize = 0; 
        while (li_sp.next()) |s| {
            if (s.len == 0)
                break; 
            const val = std.fmt.parseFloat(f16, s) catch break; 
            if (cidx >= col_size) break; 
            rst.at(ridx, cidx).* = val; 
            cidx += 1; 
        } 
    }
    return rst; 
}

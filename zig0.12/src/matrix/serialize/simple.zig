const matrix = @import("../matrix.zig"); 
const std = @import("std"); 

pub fn store(writer: anytype, m: matrix.Matrix) !void {
    // var writer = file.writer();
    // magic number 
    try writer.writeIntLittle(usize, 0xFF141307); 
    // col size / col size 
    try writer.writeIntLittle(usize, m.col);  
    try writer.writeIntLittle(usize, m.size);  
    try writer.writeIntLittle(usize, m.data.col); 
    try writer.writeIntLittle(usize, m.data.size); 
    // data 
    const buffer = m.data.data[0..m.data.size];
    const u8buffer : []const u8 = std.mem.sliceAsBytes(buffer);  
    try writer.writeAll(u8buffer);
    return ; 
}

pub fn load(reader: anytype, allocator: std.mem.Allocator) !matrix.Matrix {
    const magic = try reader.readIntLittle(usize);
    if (magic != 0xFF141307) {
        return error.InvalidMatrixFormat; 
    }
    const mcol = try reader.readIntLittle(usize); 
    const msize = try reader.readIntLittle(usize); 
    const dcol = try reader.readIntLittle(usize); 
    const dsize = try reader.readIntLittle(usize); 
    if (msize % mcol != 0) {
        return error.InvalidMatrixFormat; 
    }  
    const mrow = @divExact(msize, mcol); 
    const inner_matrix = try matrix.Matrix.init(mrow, mcol, allocator);
    errdefer inner_matrix.deinit(); 
    // check it 
    if (inner_matrix.data.size != dsize) {
        return error.InvalidMatrixFormat; 
    } 
    if (inner_matrix.data.col != dcol) {
        return error.InvalidMatrixFormat; 
    } 
    // read data 
    const buffer = inner_matrix.data.data[0..inner_matrix.data.size]; 
    const u8buffer : []u8 = std.mem.sliceAsBytes(buffer); 
    const len = try reader.readAll(u8buffer);
    if (len != u8buffer.len) {
        return error.InvalidMatrixFormat; 
    } 
    return inner_matrix; 
}
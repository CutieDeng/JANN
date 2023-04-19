pub const std = @import("std"); 

pub fn GenericMatrix(comptime TypeOfElement: type ) type {
    return struct {
        row: usize = TypeOfElement.ROW, 
        col: usize = TypeOfElement.COLUMN, 
        ptr: [*]TypeOfElement, 
        pub const InnerType = TypeOfElement; 
        pub const This = @This(); 
        pub fn init(self: *This, row_: usize, col_: usize, alloc: std.mem.Allocator) !void {
            self.row = row_; 
            self.col = col_; 
            self.ptr = try alloc.alloc(TypeOfElement, self.row * self.col);  
        }
        pub fn deinit(self: *This, alloc: std.mem.Allocator) void {
            alloc.free(self.ptr); 
        } 
        pub fn set(self: *This, row: usize, col: usize, value: TypeOfElement) void {
            self.ptr[row * self.col + col] = value; 
        } 
        pub fn get(self: *This, row: usize, col: usize) TypeOfElement {
            return self.ptr[row * self.col + col]; 
        } 
    }; 
}
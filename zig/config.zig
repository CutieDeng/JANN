pub const gpu = true; 

pub const matrix_f32_multiplication : 
    fn (a: [*] const f32, b: [*] const f32, r: [*] f32, result_rows: i64, result_columns: i64, internals: i64) callconv(.C) void 
    = @import("matrix_f32_multiplication.zig").matrix_f32_multiplication; 
pub extern fn @"swift:float32:matrix multiplication"(
    matrix_a: [*] const f32, 
    matrix_b: [*] const f32, 
    matrix_c: [*] f32, 
    result_rows: i64, 
    result_columns: i64, 
    common_dimension: i64, 
) callconv(.C) void; 

pub const matrix_f32_multiplication = @"swift:float32:matrix multiplication"; 
pub const std = @import("std");

pub const matrix = @import("matrix.zig"); 

pub const Matrix = matrix.Matrix; 
pub const DataType = matrix.DataType; 

pub fn main() !void {
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = general_allocator.allocator(); 
    defer {
        // allocator.deinit(); 
        _ = general_allocator.deinit(); 
    }
    var matrix1: matrix.Matrix = undefined;
    // data is in the file : '../java/data/train.txt' 
    // open and read the data to my Matrix. 
    var cwd = try std.fs.cwd().openFile("../java/data/train.txt", .{});
    // var file = try std.fs.openFileAbsolute("../java/data/train.txt", .{} ); 
    var file = cwd; 
    defer file.close(); 
    // read the data to the memory 
    var data = try file.readToEndAlloc(allocator, 1 << 30); 
    defer allocator.free(data); 
    // parse the data 
    // line split first ~ 
    var lines = std.mem.split(u8, data, "\n"); 
    var list = std.ArrayList(std.ArrayList(DataType)).init(allocator); 
    defer list.deinit(); 
    while (lines.next()) |line| { 
        var line_list = std.ArrayList(DataType).init(allocator); 
        var push_succ : bool = false; 
        defer {
            if (!push_succ)
                line_list.deinit(); 
        }
        var line_data = std.mem.split(u8, line, " "); 
        while (line_data.next()) |f16data| {
            var value_error = std.fmt.parseFloat(DataType, f16data); 
            if (value_error) |_| {} else |_| {
                if (f16data.len == 0) {
                    continue; 
                } 
                std.debug.print("error on parse f16: {s}\n", .{f16data}); 
            }
            var value = try value_error; 
            try line_list.append(value); 
        } 
        if (line_list.items.len == 0) {
            continue; 
        } 
        try list.append(line_list); 
        push_succ = true; 
    } 
    defer {
        for (list.items) |*item| {
            item.deinit(); 
        } 
    }
    try matrix1.init(list.items.len, list.items[0].items.len, allocator); 
    defer matrix1.deinit(); 
    {
        var i : usize = 0; 
        while (i < list.items.len) : (i += 1) {
            var j : usize = 0; 
            while (j < list.items[i].items.len) : (j += 1) {
                matrix1.data[i * matrix1.col + j] = list.items[i].items[j];
            }
        } 
    }
    // transpose the matrix 
    var transposed_matrix: Matrix = undefined; 
    try transposed_matrix.transpose_as_init(&matrix1, allocator); 
    defer transposed_matrix.deinit(); 
    var labels : Matrix = undefined; 
    var transposed_labels: Matrix = undefined; 
    {
        // read data from the file 
        var cwd_inner = try std.fs.cwd().openFile("../java/data/label.txt", .{}); 
        defer cwd_inner.close(); 
        var data_inner = std.ArrayList(std.ArrayList(DataType)).init(allocator); 
        defer data_inner.deinit(); 
        var content = try cwd_inner.readToEndAlloc(allocator, 1 << 30);
        defer allocator.free(content); 
        var lines2 = std.mem.split(u8, content, "\n"); 
        while (lines2.next()) |line| {
            var line_list = std.ArrayList(DataType).init(allocator); 
            var push_succ : bool = false; 
            defer {
                if (!push_succ)
                    line_list.deinit(); 
            }
            var line_data = std.mem.split(u8, line, " "); 
            while (line_data.next()) |f16data| {
                var value_error = std.fmt.parseFloat(DataType, f16data); 
                if (value_error) |_| {} else |_| {
                    if (f16data.len == 0) {
                        continue; 
                    } 
                    std.debug.print("error on parse f16: {s}\n", .{f16data}); 
                }
                var value = try value_error; 
                try line_list.append(value); 
            } 
            if (line_list.items.len == 0) {
                // std.debug.print("empty line: \"{s}\"\n", .{ line } ); 
                continue; 
            } 
            try data_inner.append(line_list); 
            push_succ = true; 
        } 
        defer {
            for (data_inner.items) |*item| {
                item.deinit(); 
            } 
        }
        {
            // debug ~ print the data inner size : 
            // std.debug.print("size of data inner: {} rows\n", .{ data_inner.items.len }); 
        }
        try labels.init(data_inner.items.len, data_inner.items[0].items.len, allocator);  
        defer labels.deinit(); 
        {
            var i : usize = 0; 
            while (i < data_inner.items.len) : (i += 1) {
                var j : usize = 0; 
                while (j < data_inner.items[i].items.len) : (j += 1) {
                    labels.data[i * labels.col + j] = data_inner.items[i].items[j]; 
                }
            } 
        } 
        try transposed_labels.transpose_as_init(&labels, allocator); 
    }
    defer transposed_labels.deinit(); 
    try train(allocator, &transposed_matrix, &transposed_labels); 
}

pub const my_math = struct {
    pub fn relu(input: DataType) callconv(.Inline ) DataType {
        return if (input < 0) 0 else input; 
    }
    pub fn @"relu'"(input: DataType) callconv(.Inline ) DataType {
        return if (input < 0) 0 else 1; 
    }
}; 

pub const model_arguments = struct {
    pub const Vec2 = struct {
        row: usize, 
        col: usize, 
    }; 
    pub const w1: Vec2 = .{ .row = 300, .col = 784 }; 
    pub const w2 : Vec2 = .{ .row = 100, .col = 300 }; 
    pub const w3 : Vec2 = .{ .row = 10, .col = 100 }; 
}; 

pub const Context = struct {
    w1: Matrix, 
    b1: Matrix, 
    w2: Matrix, 
    b2: Matrix, 
    w3: Matrix, 
    b3: Matrix, 
};   

pub const ForwardContext = struct {
    z1: Matrix, 
    a1: Matrix, 
    z2: Matrix, 
    a2: Matrix, 
    z3: Matrix, 
    a3: Matrix, 
}; 

pub const BackwardContext = struct {
    d3: Matrix, 
    d2: Matrix, 
    d1: Matrix, 
    w3: Matrix, 
    w2: Matrix, 
    w1: Matrix,
    b3: Matrix, 
    b2: Matrix, 
    b1: Matrix, 
    buffer: BufferContext, 
};

pub const BufferContext = struct {
    a2_t: Matrix, 
    w3_t: Matrix,
    w3: Matrix, 
    a1_t: Matrix, 
    w2_t: Matrix, 
    w2: Matrix, 
    a0_t: Matrix, 
    w1_t: Matrix, 
    w1: Matrix,
}; 

pub fn train(allocator: std.mem.Allocator, input: *const Matrix, labels: *const Matrix) !void {

    var context: Context = undefined; 

    var random = std.rand.DefaultPrng.init(0); 
    var random2 = random.random(); 

    try context.w1.init(model_arguments.w1.row, input.row, allocator); 
    defer context.w1.deinit(); 
    try context.b1.init(model_arguments.w1.row, 1, allocator); 
    defer context.b1.deinit(); 
    try context.w2.init(model_arguments.w2.row, model_arguments.w2.col, allocator); 
    defer context.w2.deinit(); 
    try context.b2.init(model_arguments.w2.row, 1, allocator); 
    defer context.b2.deinit(); 
    try context.w3.init(model_arguments.w3.row, model_arguments.w3.col, allocator); 
    defer context.w3.deinit(); 
    try context.b3.init(model_arguments.w3.row, 1, allocator); 
    defer context.b3.deinit(); 

    var offset = @intToFloat( DataType, context.w1.row  + context.w1.col ); 
    for (context.w1.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset * (tmp - 0.5) ); 
    } 
    var offset2 = @intToFloat( DataType, context.b1.row + context.b1.col ); 
    for (context.b1.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset2 * (tmp - 0.5) ); 
    } 
    var offset3 = @intToFloat( DataType, context.w2.row + context.w2.col ); 

    for (context.w2.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset3 * (tmp - 0.5) ); 
    } 
    var offset4 = @intToFloat( DataType, context.b2.row + context.b2.col ); 
    for (context.b2.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset4 * (tmp - 0.5) ); 
    } 
    var offset5 = @intToFloat( DataType, context.w3.row + context.w3.col ); 
    for (context.w3.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset5 * (tmp - 0.5) ); 
    } 
    var offset6 = @intToFloat( DataType, context.b3.row + context.b3.col ); 
    for (context.b3.mut_slice()) |*item| { 
        var tmp = random2.float(f32); 
        item.* = @floatCast( DataType , 6 / offset6 * (tmp - 0.5) ); 
    } 
    try trains(allocator, &context, input, labels); 
} 

pub fn trains(allocator: std.mem.Allocator, context: *Context, input: *const Matrix, labels: *const Matrix) !void {
    var forward_context: ForwardContext = undefined; 
    try forward_context.a1.init(model_arguments.w1.row, input.col, allocator); 
    try forward_context.a2.init(model_arguments.w2.row, input.col, allocator); 
    try forward_context.a3.init(model_arguments.w3.row, input.col, allocator); 
    try forward_context.z1.init(model_arguments.w1.row, input.col, allocator); 
    try forward_context.z2.init(model_arguments.w2.row, input.col, allocator); 
    try forward_context.z3.init(model_arguments.w3.row, input.col, allocator); 
    defer {
        forward_context.a1.deinit(); 
        forward_context.a2.deinit(); 
        forward_context.a3.deinit(); 
        forward_context.z1.deinit(); 
        forward_context.z2.deinit(); 
        forward_context.z3.deinit(); 
    }
    var backward_context: BackwardContext = undefined; 
    try backward_context.d1.init(model_arguments.w1.row, input.col, allocator); 
    try backward_context.d2.init(model_arguments.w2.row, input.col, allocator); 
    try backward_context.d3.init(model_arguments.w3.row, input.col, allocator); 
    try backward_context.w1.init(model_arguments.w1.row, input.row, allocator); 
    try backward_context.w2.init(model_arguments.w2.row, model_arguments.w2.col, allocator); 
    try backward_context.w3.init(model_arguments.w3.row, model_arguments.w3.col, allocator); 
    try backward_context.b1.init(model_arguments.w1.row, 1, allocator); 
    try backward_context.b2.init(model_arguments.w2.row, 1, allocator); 
    try backward_context.b3.init(model_arguments.w3.row, 1, allocator); 
    try backward_context.buffer.a0_t.init(input.col, input.row, allocator); 
    try backward_context.buffer.a1_t.init(forward_context.a1.col, forward_context.a1.row, allocator); 
    try backward_context.buffer.a2_t.init(forward_context.a2.col, forward_context.a2.row, allocator); 
    try backward_context.buffer.w1_t.init(model_arguments.w1.col, model_arguments.w1.row, allocator); 
    try backward_context.buffer.w2_t.init(model_arguments.w2.col, model_arguments.w2.row, allocator); 
    try backward_context.buffer.w3_t.init(model_arguments.w3.col, model_arguments.w3.row, allocator); 
    try backward_context.buffer.w1.init(model_arguments.w1.row, model_arguments.w1.col, allocator); 
    try backward_context.buffer.w2.init(model_arguments.w2.row, model_arguments.w2.col, allocator); 
    try backward_context.buffer.w3.init(model_arguments.w3.row, model_arguments.w3.col, allocator); 
    defer {
        backward_context.b1.deinit(); 
        backward_context.b2.deinit(); 
        backward_context.b3.deinit(); 
        backward_context.w1.deinit(); 
        backward_context.w2.deinit(); 
        backward_context.w3.deinit(); 
        backward_context.d1.deinit(); 
        backward_context.d2.deinit(); 
        backward_context.d3.deinit(); 
        backward_context.buffer.a0_t.deinit(); 
        backward_context.buffer.a1_t.deinit(); 
        backward_context.buffer.a2_t.deinit(); 
        backward_context.buffer.w1_t.deinit(); 
        backward_context.buffer.w2_t.deinit(); 
        backward_context.buffer.w3_t.deinit(); 
        backward_context.buffer.w1.deinit(); 
        backward_context.buffer.w2.deinit(); 
        backward_context.buffer.w3.deinit(); 
    }
    while (true) {
        if (false) {
            const row : usize = context.w3.row; 
            const col : usize = context.w3.col; 
            var row_i : usize = 0; 
            var col_i : usize = 0; 
            while (row_i < row) : (row_i += 1) {
                while (col_i < col) : (col_i += 1) {
                    std.debug.print("{} ", .{ context.w3.data[row_i * col + col_i ]}); 
                }
                std.debug.print("\n", .{}); 
                col_i = 0; 
            }
            std.debug.print("{s}", .{ "---\n" }); 
        }
        try train_one_round(allocator, context, input, labels, &forward_context, &backward_context);
        // print forward context result: 
        if (false) {
            var row : usize = forward_context.a3.row; 
            var cols : usize = forward_context.a3.col; 
            var col : usize = 13; 
            var row_index : usize = 0; 
            var col_index : usize = 0; 
            while (row_index < row) : (row_index += 1) {
                while (col_index < col) : (col_index += 1) {
                    std.debug.print("{} ", .{ forward_context.a3.data[row_index * cols + col_index] }); 
                }
                std.debug.print("\n", .{}); 
                col_index = 0; 
            } 
        }
    } 
}

pub fn train_one_round(allocator: std.mem.Allocator, context: *Context, input: *const Matrix, labels: *const Matrix, forward_context: *ForwardContext, 
    backward_context: *BackwardContext) !void {
    try forward(forward_context, context, input, allocator); 
    if (true) {
        var loss = loss_function(forward_context, labels); 
        // if loss is NaN or Inf, then stop training 
        if (std.math.isNan(loss) or std.math.isInf(loss)) {
            std.debug.print("LOSS = {}\n", .{ loss }); 
            return error.LossIsNaNOrInf; 
        } 
        std.debug.print("LOSS = {}\n", .{ loss }); 
    }
    try backward(backward_context, context, forward_context, labels, input, allocator); 
    { 
        const learning_rate : DataType = -1e-7; 
        const matrixes = [_]*Matrix{ &backward_context.w1, &backward_context.w2, &backward_context.w3, &backward_context.b1, &backward_context.b2, &backward_context.b3 }; 
        inline for (matrixes) |m| {
            for (m.mut_slice()) |*data| {
                data.* *= learning_rate; 
            } 
        } 
    }
    try update(context, backward_context, allocator); 
}

pub fn update(context: *Context, backward_context: *const BackwardContext, allocator: std.mem.Allocator) !void {
    try context.w1.add_assign(&backward_context.w1); 
    try context.b1.add_assign(&backward_context.b1); 
    try context.w2.add_assign(&backward_context.w2); 
    try context.b2.add_assign(&backward_context.b2); 
    try context.w3.add_assign(&backward_context.w3); 
    try context.b3.add_assign(&backward_context.b3); 
    _ = allocator; 
} 

pub const RngGen = std.rand.DefaultPrng; 

pub fn forward(forward_context: *ForwardContext, context: *const Context, input: *const Matrix, allocator: std.mem.Allocator) !void {
    try forward_context.z1.multiply_assign(&context.w1, input); 
    try forward_context.z1.add_vec_assign(&context.b1); 
    try forward_context.a1.assign(&forward_context.z1); 
    for (forward_context.a1.mut_slice()) |*item| {
        item.* = my_math.relu(item.*); 
    } 
    try forward_context.z2.multiply_assign(&context.w2, &forward_context.a1); 
    try forward_context.z2.add_vec_assign(&context.b2); 
    try forward_context.a2.assign(&forward_context.z2); 
    for (forward_context.a2.mut_slice()) |*item| {
        item.* = my_math.relu(item.*); 
    } 
    try forward_context.z3.multiply_assign(&context.w3, &forward_context.a2); 
    try forward_context.z3.add_vec_assign(&context.b3); 
    try forward_context.a3.assign(&forward_context.z3); 
    for (forward_context.a3.mut_slice()) |*item| {
        var tmp = item.*; 
        tmp = @exp2(tmp); 
        if (std.math.isInf(tmp) or std.math.isNan(tmp)) {
            std.debug.print("exp {} = {}\n", .{ item.*, tmp }); 
            return error.NanOrInf; 
        }
        item.* = tmp; 
    } 
    // every col as a data ~ 
    var sums : []DataType = try allocator.alloc(DataType, forward_context.a3.col); 
    defer allocator.free(sums); 
    for (sums) |*sum| {
        sum.* = 0; 
    } 
    for (forward_context.a3.const_slice(), 0..) |val, i| {
        sums[i % forward_context.a3.col] += val;  
    }
    for (forward_context.a3.mut_slice(), 0..) |*value, i| { 
        var tmp = value.*; 
        tmp /= sums[i % forward_context.a3.col]; 
        value.* = tmp; 
    } 
}

pub fn loss_function(forward_context: *const ForwardContext, labels: *const Matrix) f64 {
    var loss: f64 = 0; 
    for (forward_context.a3.const_slice(), labels.const_slice()) |value, i| {
        loss += -i * @log(value); 
    } 
    loss /= @intToFloat(f64, forward_context.a3.col); 
    return loss; 
} 

pub const is_keep = true; 
pub const lambda : DataType = 0.001; 

pub fn backward(backward_context: *BackwardContext, context: *const Context, forward_context: *const ForwardContext, labels: *const Matrix, input: *const Matrix, allocator: std.mem.Allocator) Matrix.MatrixError !void {
    _ = allocator; 
    try backward_context.d3.assign(&forward_context.a3);
    try backward_context.d3.minus_assign(labels); 
    try backward_context.buffer.a2_t.transpose_assign(&forward_context.a2); 
    try backward_context.w3.multiply_assign(&backward_context.d3, &backward_context.buffer.a2_t); 
    if (is_keep) {
        try backward_context.buffer.w3.assign(&context.w3); 
        for (backward_context.buffer.w3.mut_slice()) |*item| {
            item.* *= lambda; 
        } 
        try backward_context.w3.add_assign(&backward_context.buffer.w3); 
    }
    try backward_context.b3.sum_to_col_vec(&backward_context.d3); 
    for (backward_context.b3.mut_slice()) |*item| {
        item.* /= @intToFloat(DataType, backward_context.d3.col); 
    } 
    try backward_context.buffer.w3_t.transpose_assign(&context.w3); 
    try backward_context.d2.multiply_assign(&backward_context.buffer.w3_t, &backward_context.d3); 
    for (backward_context.d2.mut_slice(), forward_context.a2.const_slice()) |*item, val| {
        item.* *= my_math.@"relu'" (val); 
    } 
    try backward_context.buffer.a1_t.transpose_assign(&forward_context.a1); 
    try backward_context.w2.multiply_assign(&backward_context.d2, &backward_context.buffer.a1_t); 
    if (is_keep) {
        try backward_context.buffer.w2.assign(&context.w2); 
        for (backward_context.buffer.w2.mut_slice()) |*item| {
            item.* *= lambda; 
        } 
        try backward_context.w2.add_assign(&backward_context.buffer.w2); 
    } 
    try backward_context.b2.sum_to_col_vec(&backward_context.d2); 
    for (backward_context.b2.mut_slice()) |*item| {
        item.* /= @intToFloat(DataType, backward_context.d2.col); 
    } 
    try backward_context.buffer.w2_t.transpose_assign(&context.w2); 
    try backward_context.d1.multiply_assign(&backward_context.buffer.w2_t, &backward_context.d2); 
    for (backward_context.d1.mut_slice(), forward_context.a1.const_slice()) |*item, val| {
        item.* *= my_math.@"relu'" (val); 
    } 
    try backward_context.buffer.a0_t.transpose_assign(input); 
    try backward_context.w1.multiply_assign(&backward_context.d1, &backward_context.buffer.a0_t); 
    if (is_keep) {
        try backward_context.buffer.w1.assign(&context.w1); 
        for (backward_context.buffer.w1.mut_slice()) |*item| {
            item.* *= lambda; 
        } 
        try backward_context.w1.add_assign(&backward_context.buffer.w1); 
    } 
    try backward_context.b1.sum_to_col_vec(&backward_context.d1); 
    for (backward_context.b1.mut_slice()) |*item| {
        item.* /= @intToFloat(DataType, backward_context.d1.col); 
    }
} 
pub fn FixedMatrix(comptime row_number_of_matrix: usize, comptime col_number_of_matrix: usize, comptime TypeOfElement: type) type {
    return struct {
        pub const ROW = row_number_of_matrix; 
        pub const COLUMN = col_number_of_matrix; 
        pub const InnerType = TypeOfElement; 
        pub const This = @This(); 
        array : [ROW * COLUMN] InnerType, 
        pub fn get(self: *const This, row: usize, col: usize) callconv(.Always_inline) InnerType {
            return self.array[row * This.COLUMN + col]; 
        } 
        pub fn set(self: *This, row: usize, col: usize, value: InnerType) callconv(.Always_inline) void {
            self.array[row * This.COLUMN + col] = value; 
        } 
        pub fn add_assign(self: *This, other: *const This) callconv(.Always_inline) void {
            for (self.array, other.array) |*element, ele2| {
                element.* += ele2; 
            } 
        } 
        pub fn minus_assign(self: *This, other: *const This) callconv(.Always_inline) void {
            for (self.array, other.array) |*element, ele2| {
                element.* -= ele2; 
            } 
        } 
        pub fn dot_assign(self: *This, other: *const This) callconv(.Always_inline) void {
            for (self.array, other.array) |*element, ele2| {
                element.* *= ele2; 
            } 
        } 
        pub fn add_assign_scalar(self: *This, scalar: InnerType) callconv(.Always_inline) void {
            for (self.array) |*element| {
                element.* += scalar; 
            } 
        } 
        pub fn minus_assign_scalar(self: *This, scalar: InnerType) callconv(.Always_inline) void {
            for (self.array) |*element| {
                element.* -= scalar; 
            } 
        } 
        pub fn divide_assign_scalar(self: *This, scalar: InnerType) callconv(.Always_inline) void {
            for (self.array) |*element| {
                element.* /= scalar; 
            } 
        } 
        pub fn dot_assign_scalar(self: *This, scalar: InnerType) callconv(.Always_inline) void {
            for (self.array) |*element| {
                element.* *= scalar; 
            } 
        } 
        pub fn add_assign_vector(self: *This, vec: anytype) callconv(.Always_inline) void {
            const TypeOfVec = @TypeOf(vec); 
            const is_row_vec = TypeOfVec.ROW == 1; 
            const is_col_vec = TypeOfVec.COLUMN == 1; 
            if (is_row_vec and is_col_vec) {
                @compileError("The type of vec is not a vector but a scalar"); 
            } 
            if (!(is_row_vec or is_col_vec)) {
                @compileError("The type of vec is not a vector"); 
            } 
            if (is_row_vec) {
                if (TypeOfVec.COLUMN != This.COLUMN) {
                    @compileError("The column number of the vector is not equal to the column number of the matrix"); 
                } 
                var col_iter = 0; 
                for (self.array) |*element| {
                    element.* += vec.get(0, col_iter); 
                    col_iter += 1; 
                    if (col_iter == This.COLUMN) {
                        col_iter = 0; 
                    } 
                } 
            } else {
                if (TypeOfVec.ROW != This.ROW) {
                    @compileError("The row number of the vector is not equal to the row number of the matrix"); 
                } 
                var row_iter = 0; 
                var col_iter = 0; 
                for (self.array) |*element| {
                    element.* += vec.get(row_iter, 0); 
                    col_iter += 1; 
                    if (col_iter == This.COLUMN) {
                        col_iter = 0; 
                        row_iter += 1; 
                    } 
                }  
            } 
        } 
        pub fn clone(self: *This, other: *const This) callconv(.Always_inline) void {
            self.array = other.array; 
        } 
    }; 
}